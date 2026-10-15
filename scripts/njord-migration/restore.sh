#!/usr/bin/env bash
# Restore njord's VMs and host config from a backup.sh folder on TrueNAS, onto a FRESH
# Proxmox install (hostname njord, 10.10.0.5, local-lvm thin pool).
# Run ON njord as root, from the backup folder:
#
#   bash restore.sh --dry-run    # show what would happen
#   bash restore.sh              # host config + all VMs, then start the ones that were running
#   bash restore.sh --only "102 103"   --no-start   --skip-host
set -euo pipefail

DIR=$(cd "$(dirname "$0")" && pwd)
TARGET=${TARGET:-local-lvm}

DRY=0 START=1 HOST=1 YES=0 ONLY=""
while (($#)); do
  case $1 in
    --dry-run) DRY=1 ;;
    --no-start) START=0 ;;
    --skip-host) HOST=0 ;;
    --only) ONLY=$2; shift ;;
    -y|--yes) YES=1 ;;
    -h|--help) sed -n 2,9p "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

say() { printf '\n\033[1;35m== %s\033[0m\n' "$*"; }
die() { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }
run() { if ((DRY)); then echo "[dry-run] $*"; else "$@"; fi; }

say "Preflight"
[[ $EUID -eq 0 ]] || die "run as root"
[[ $(hostname) == njord ]] || die "this isn't njord ($(hostname))"
[[ -e $DIR/BACKUP_OK ]] || die "$DIR has no BACKUP_OK marker; the backup didn't finish"
[[ -e $DIR/host-config.tgz ]] || die "host-config.tgz missing"
pvesm status --storage "$TARGET" 2>/dev/null | grep -q ' active ' || die "storage $TARGET is not active"

declare -A ARCHIVE
for f in "$DIR"/vzdump-qemu-*.vma.zst; do
  id=$(basename "$f" | cut -d- -f3)
  [[ -n $ONLY && " $ONLY " != *" $id "* ]] && continue
  ARCHIVE[$id]=$f
done
mapfile -t IDS < <(printf '%s\n' "${!ARCHIVE[@]}" | sort -n)
((${#IDS[@]})) || die "no archives to restore"
mapfile -t RUNNING < <(grep -E '^[0-9]+$' "$DIR/running.txt" 2>/dev/null || true)

pool_g=$(lvs --noheadings --units g --nosuffix -o lv_size pve/data 2>/dev/null | tr -d ' ' | cut -d. -f1)
echo "Backup: $DIR ($(cat "$DIR/BACKUP_OK"))"
echo "Restore VMs: ${IDS[*]} -> $TARGET (thin pool ${pool_g:-?}G)"
echo "Start afterwards: $( ((START)) && echo "${RUNNING[*]:-none}" || echo no)"
grep -E '^ +(vm|base)-' "$DIR/manifest.txt" | awk '{print "  was:", $1, $4, "used " $6 "%"}' || true

if ((!DRY && !YES)); then
  read -r -p "Go? [y/N] " ok; [[ $ok == [yY]* ]] || die "aborted"
fi

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
tar -xzf "$DIR/host-config.tgz" -C "$TMP"
S=$TMP   # saved copy of the old host's files, same paths under $S

if ((HOST)); then
  say "Host config"
  # Cloud-init snippets referenced by every VM (cicustom: local:snippets/...)
  run mkdir -p /var/lib/vz/snippets
  run cp -av "$S/var/lib/vz/snippets/." /var/lib/vz/snippets/

  # PVE users + API tokens (terraform-prov@pve keeps working) and the GPU PCI mapping
  for f in user.cfg priv/token.cfg mapping/pci.cfg; do
    [[ -e $S/etc/pve/$f ]] || continue
    [[ -e /etc/pve/$f ]] && run cp -a "/etc/pve/$f" "/root/$(basename "$f").fresh-install"
    run mkdir -p "$(dirname "/etc/pve/$f")"
    run cp "$S/etc/pve/$f" "/etc/pve/$f"
  done

  # SSH keys for root (PVE keeps them in /etc/pve/priv/authorized_keys)
  if [[ -e $S/root/.ssh/authorized_keys ]]; then
    while read -r line; do
      [[ -z $line ]] && continue
      grep -qxF "$line" /root/.ssh/authorized_keys 2>/dev/null || run sh -c "printf '%s\n' \"\$1\" >> /root/.ssh/authorized_keys" _ "$line"
    done < "$S/root/.ssh/authorized_keys"
  fi

  # ansible service account (fairgrounds-infra connects as ansible with passwordless sudo)
  id ansible >/dev/null 2>&1 || run useradd -m -s /bin/bash ansible
  run install -d -m 700 -o ansible -g ansible /home/ansible/.ssh
  [[ -e $S/home/ansible/.ssh/authorized_keys ]] &&
    run install -m 600 -o ansible -g ansible "$S/home/ansible/.ssh/authorized_keys" /home/ansible/.ssh/authorized_keys
  command -v sudo >/dev/null || run apt-get install -y sudo
  [[ -e $S/etc/sudoers.d/ansible ]] && run install -m 440 "$S/etc/sudoers.d/ansible" /etc/sudoers.d/ansible

  # apt repos (no-subscription vs enterprise), same as before. tailscale.list skipped: needs its keyring.
  for f in "$S"/etc/apt/sources.list.d/*.sources; do run cp "$f" /etc/apt/sources.list.d/; done

  # GPU passthrough (vfio + IOMMU kernel args). Needs a reboot to take effect.
  REBOOT=0
  for f in vfio.conf kvm.conf iommu_unsafe_interrupts.conf blacklist.conf; do
    [[ -e $S/etc/modprobe.d/$f ]] && { run cp "$S/etc/modprobe.d/$f" /etc/modprobe.d/; REBOOT=1; }
  done
  [[ -e $S/etc/modules-load.d/05-vfio.conf ]] && run cp "$S/etc/modules-load.d/05-vfio.conf" /etc/modules-load.d/
  old=$(grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=' "$S/etc/default/grub" 2>/dev/null || true)
  if [[ -n $old ]] && ! grep -qxF "$old" /etc/default/grub; then
    run sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|$old|" /etc/default/grub
    REBOOT=1
  fi
  if ((REBOOT)); then
    run update-initramfs -u -k all
    run update-grub
    if command -v proxmox-boot-tool >/dev/null; then run proxmox-boot-tool refresh; fi
  fi
fi

say "Restoring VMs"
for id in "${IDS[@]}"; do
  if qm status "$id" >/dev/null 2>&1; then echo "-- $id already exists, skipping"; continue; fi
  echo "-- $id from $(basename "${ARCHIVE[$id]}")"
  start=$(date +%s)
  run qmrestore "${ARCHIVE[$id]}" "$id" --storage "$TARGET" --unique 0
  ((DRY)) || echo "   done in $((($(date +%s) - start) / 60)) min"
done

if ((START)) && ((${#RUNNING[@]})); then
  say "Starting VMs (europa first for caddy/DNS-ish services, arethusa last)"
  ORDER=(); [[ " ${RUNNING[*]} " == *" 102 "* ]] && ORDER+=(102)
  for id in "${RUNNING[@]}"; do [[ $id == 102 || $id == 104 ]] || ORDER+=("$id"); done
  [[ " ${RUNNING[*]} " == *" 104 "* ]] && ORDER+=(104)
  for id in "${ORDER[@]}"; do
    [[ -n ${ARCHIVE[$id]:-} ]] || continue
    run qm start "$id"
    if ((!DRY)); then
      for _ in $(seq 36); do qm agent "$id" ping >/dev/null 2>&1 && break; sleep 5; done
      qm agent "$id" ping >/dev/null 2>&1 && echo "   $id is up" || echo "   $id started, but no guest agent reply yet"
    fi
  done
fi

say "Done"
qm list
cat <<EOF

Next:
  - from your laptop: cd fairgrounds-infra && ./run ping      (all VMs + njord should answer)
  - $( ((${REBOOT:-0})) && echo "reboot njord when convenient to load the GPU passthrough (vfio) config" || echo "no reboot needed")
  - tailscale on the host: ansible-playbook playbooks/setup/tailscale.yaml --limit njord (if you still want it)
  - node_exporter on the host: ansible-playbook playbooks/setup/node_exporter.yml --limit njord
  - the fresh install's originals are in /root/*.fresh-install
EOF
