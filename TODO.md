# TODO

Open items from the post-drive-replacement health check (2026-10-15).

## Fix

- [ ] **dawarich_sidekiq (daphne) never starts.** It sits in `Created` while
  `dawarich_app` runs, so background jobs aren't processed. `dawarich_app` is
  also marked unhealthy: Puma logs `Invalid HTTP format ... SSL connection to a
  non-SSL Puma?` every 30s, so the healthcheck likely hits it over HTTPS.
- [ ] **No SSH access to njord.** `ansible@10.10.0.5` rejects
  `secrets/id_ed25519` (publickey,password). Re-add the ansible key after the
  re-image.
- [ ] **No SSH access to homeassistant.** `julian@10.10.0.30` rejects
  `secrets/id_ed25519`. Add the key or fix `ansible_user` in `inventory.yaml`.
- [ ] **`mnt-EricBackup.mount` fails on every VM.** The fstab entry for
  `//10.10.0.6/EricBackup` uses `uid=eric,gid=eric`, but there's no `eric`
  user, so mount rejects the options. It failed before the drive swap too
  (Oct 8). Either use numeric ids, create the user, or drop the entry.
- [ ] **Broken healthchecks on outreach (ceto) and bookwyrm (daphne).** Both
  call `wget`, which isn't in the images, so they report unhealthy while the
  apps run fine. Switch to a check the image supports (e.g. `node -e fetch`).
- [ ] **demeter (10.10.0.50) doesn't answer ping.** Check whether it's just
  off.

## Someday

- [ ] **ceto has no GPU.** No NVIDIA device shows up in `lspci` since the
  hardware change. Passthrough hasn't worked reliably in the past, so it's
  parked for now.
