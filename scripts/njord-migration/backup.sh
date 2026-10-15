#!/usr/bin/env bash
# Back up every njord VM plus the host config to TrueNAS, ahead of re-imaging njord's disk.
# Run ON njord as root, inside tmux: arethusa (Iris) shuts down partway through.
#
#   bash backup.sh --dry-run     # show what would happen
#   bash backup.sh               # shut VMs down, back them up, verify, leave them off
#   bash backup.sh --restart     # same, then start the VMs that were running
set -euo pipefail

STORAGE=${STORAGE:-truenas-backup}            # PVE NFS storage -> 10.10.0.6:/mnt/Robust/Store
MNT=/mnt/pve/$STORAGE
DEST=${DEST:-$MNT/Backups/Njord/migration-$(date +%F)}
SKIP=${SKIP:-101}                             # metis-dead: already imaged in njord_recovery/
SHUTDOWN_TIMEOUT=${SHUTDOWN_TIMEOUT:-300}

DRY=0 RESTART=0 VERIFY=1 YES=0
for a in "$@"; do
  case $a in
    --dry-run) DRY=1 ;;
    --restart) RESTART=1 ;;
    --no-verify) VERIFY=0 ;;
    -y|--yes) YES=1 ;;
    -h|--help) sed -n 2,8p "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

say() { printf '\n\033[1;35m== %s\033[0m\n' "$*"; }
die() { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }
run() { if ((DRY)); then echo "[dry-run] $*"; else "$@"; fi; }
HERE=$(cd "$(dirname "$0")" && pwd)

say "Preflight"
[[ $EUID -eq 0 ]] || die "run as root"
[[ $(hostname) == njord ]] || die "this isn't njord ($(hostname))"
pvesm status --storage "$STORAGE" 2>/dev/null | grep -q ' active ' || die "storage $STORAGE is not active"
mountpoint -q "$MNT" || die "$MNT is not mounted"
if ((!DRY)); then
  touch "$MNT/.njord-write-test" && rm -f "$MNT/.njord-write-test" || die "can't write to $MNT"
fi
command -v zstd >/dev/null || die "zstd missing"
[[ -e $DEST/BACKUP_OK ]] && die "$DEST already has a finished backup; set DEST=... to make another"
if [[ -z ${TMUX:-}${STY:-} ]] && ((!YES && !DRY)); then
  die "not inside tmux/screen. If your SSH drops (or you're on arethusa) the run dies with it. Use: tmux new -s backup   (or pass --yes)"
fi

mapfile -t ALL < <(qm list | awk 'NR>1 {print $1}')
IDS=() RUNNING=()
for id in "${ALL[@]}"; do
  [[ " $SKIP " == *" $id "* ]] && continue
  IDS+=("$id")
  qm status "$id" | grep -q running && RUNNING+=("$id")
done
((${#IDS[@]})) || die "no VMs to back up"
free_kb=$(df -Pk "$MNT" | awk 'NR==2 {print $4}')
used_g=$(lvs --noheadings --units g --nosuffix -o lv_name,lv_size,data_percent pve 2>/dev/null \
  | awk '$1 ~ /^(vm|base)-/ && $3 != "" {s += $2 * $3 / 100} END {printf "%d", s}')
echo "VMs to back up: ${IDS[*]}   (skipping: $SKIP)"
echo "Currently running: ${RUNNING[*]:-none}"
echo "Destination: $DEST"
echo "Data on VM disks: ~${used_g}G before compression; free on NAS: $((free_kb / 1024 / 1024))G"
((free_kb / 1024 / 1024 > used_g)) || die "not enough space on the NAS"
qm list

say "Host config snapshot"
run mkdir -p "$DEST"
HOSTPATHS=(/etc/pve /etc/network/interfaces /etc/hosts /etc/hostname /etc/resolv.conf
  /var/lib/vz/snippets /etc/modprobe.d /etc/modules-load.d /etc/default/grub /etc/kernel
  /etc/sudoers.d/ansible /home/ansible/.ssh /root/.ssh /etc/apt/sources.list.d)
existing=(); for p in "${HOSTPATHS[@]}"; do [[ -e $p ]] && existing+=("$p"); done
run tar -czf "$DEST/host-config.tgz" --ignore-failed-read "${existing[@]}"
run cp "$HERE/restore.sh" "$HERE/README.md" "$DEST/"
if ((!DRY)); then
  {
    echo "# njord backup $(date -Is)"
    echo "vms: ${IDS[*]}"
    echo "running: ${RUNNING[*]:-}"
    echo; qm list; echo; pvesm status; echo; lvs --units g pve
    for id in "${IDS[@]}"; do echo; echo "== $id.conf"; qm config "$id"; done
  } > "$DEST/manifest.txt"
  printf '%s\n' "${RUNNING[@]}" > "$DEST/running.txt"
fi

if ((!DRY && !YES)); then
  echo; read -r -p "Shut down ${RUNNING[*]:-nothing} and start the backup? [y/N] " ok
  [[ $ok == [yY]* ]] || die "aborted (host-config.tgz was still written)"
fi

say "Shutting down running VMs (arethusa last)"
ORDER=(); for id in "${RUNNING[@]}"; do [[ $id == 104 ]] || ORDER+=("$id"); done
[[ " ${RUNNING[*]} " == *" 104 "* ]] && ORDER+=(104)
for id in "${ORDER[@]}"; do
  echo "-- $id $(qm config "$id" | awk '/^name:/ {print $2}')"
  run qm shutdown "$id" --timeout "$SHUTDOWN_TIMEOUT" || die "VM $id didn't shut down cleanly; check it, then re-run"
done
if ((!DRY)); then
  for id in "${IDS[@]}"; do qm status "$id" | grep -q stopped || die "VM $id is still running"; done
fi

say "Backing up (vzdump, zstd) - roughly 5-8 min per VM"
start=$(date +%s)
run vzdump "${IDS[@]}" --mode stop --compress zstd --zstd 0 --dumpdir "$DEST" \
  --notes-template '{{guestname}} (njord migration)'
((DRY)) || echo "vzdump finished in $((($(date +%s) - start) / 60)) min"

if ((!DRY)); then
  say "Checking archives"
  for id in "${IDS[@]}"; do
    n=$(compgen -G "$DEST/vzdump-qemu-$id-*.vma.zst" | wc -l || true)
    ((n == 1)) || die "expected 1 archive for VM $id, found $n"
  done
  if ((VERIFY)); then
    for f in "$DEST"/vzdump-qemu-*.vma.zst; do
      printf '%s ... ' "$(basename "$f")"
      zstd -tq "$f" && echo ok || die "$f is corrupt; do NOT re-image"
    done
  fi
  ls -lh "$DEST"
  date -Is > "$DEST/BACKUP_OK"
fi

if ((RESTART)); then
  say "Starting VMs that were running"
  for id in "${RUNNING[@]}"; do run qm start "$id"; done
fi

say "Done"
echo "Backup: $DEST"
((RESTART)) || echo "VMs are left OFF, so nothing changes after the backup. Ready to re-image."
echo "After the re-image, see README.md in that folder (short version: add the NFS storage, run restore.sh)."
