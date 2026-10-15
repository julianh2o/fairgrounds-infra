# njord disk migration

Back up every VM on njord to TrueNAS, re-image njord's disk, then restore everything.
Both scripts run **on njord as root**. Backups go to
`truenas-backup` (10.10.0.6:/mnt/Robust/Store) → `Backups/Njord/migration-<date>/`.

What gets backed up: every VM except 101 `metis-dead` (already imaged in `njord_recovery/`):
ceto 100, europa 102, daphne 103, arethusa 104, metis 105, and the ubuntu-cloud template 8000.
Also a host-config snapshot: `/etc/pve` (users, API tokens, PCI mapping), cloud-init snippets,
network config, vfio/IOMMU settings, the ansible account and SSH keys, and the apt repos.

## 1. Back up (before the re-image)

```sh
./run njord push-migration-scripts          # from your laptop: copies this folder to njord:/root/njord-migration
ssh root@10.10.0.5
tmux new -s backup                          # arethusa (Iris) goes down mid-run; don't run it from there
bash /root/njord-migration/backup.sh --dry-run
bash /root/njord-migration/backup.sh
```

It shuts down the running VMs cleanly (arethusa last), runs `vzdump --mode stop`, checks every
archive with `zstd -t`, and writes `BACKUP_OK`. VMs stay **off** afterwards so nothing changes
after the backup (`--restart` starts them again instead). About 5–8 min per VM, plus verification.

**Don't re-image until the script prints Done and the folder has `BACKUP_OK`.**

## 2. Re-image

Proxmox installer: hostname `njord` (same FQDN as before), IP `10.10.0.5/24`, gateway `10.10.0.1`,
ext4/LVM so you get `local-lvm` again. The old disk used ~370G of VM data, so the new thin pool needs
more than that.

## 3. Restore

```sh
ssh root@10.10.0.5        # password from the installer; the old SSH keys come back during restore
pvesm add nfs truenas-backup --server 10.10.0.6 --export /mnt/Robust/Store --content backup --options vers=3
cd /mnt/pve/truenas-backup/Backups/Njord/migration-*/
bash restore.sh --dry-run
bash restore.sh
```

It puts the host config back (snippets, users and tokens so terraform keeps working, PCI mapping,
ansible user, SSH keys, apt repos, vfio and kernel args), restores each VM with its original ID and
MAC, then starts the ones that were running (europa first, arethusa last). Re-running is safe: VMs
that already exist are skipped.

Then: `./run ping` from your laptop, reboot njord when convenient (for vfio), and re-run the
tailscale / node_exporter setup playbooks for njord if you want them.

Options: `--only "102 103"`, `--no-start`, `--skip-host`, `-y` (no prompt).
