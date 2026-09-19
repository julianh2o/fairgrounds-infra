# Scripts

Utility scripts for managing and monitoring infrastructure.

## formatDockerState

Format Docker container state snapshots into a simple summary.

**Usage:**
```bash
./scripts/formatDockerState reports/docker/melinoe_*.json
```

**Features:**
- Groups containers by Docker Compose project (using `com.docker.compose.project` label)
- Shows container counts per service
- Separates managed services from unmanaged containers
- Alphabetically sorted output

**Example Output:**
```
Docker Container Summary
========================

Managed Services:
  caddy: 1 running container
  grafana: 1 running container
  immich: 4 running containers
  myflix: 15 running containers
  prometheus: 1 running container

Other: 2 running containers

Total: 24 running container(s)
```

## manage_secret.py

Manage keys in the encrypted `secrets.yml` (ansible-vault) without hand-editing the
vault file.

**Usage:**
```bash
python3 scripts/manage_secret.py new <key> [value]   # add a secret (random value if omitted)
python3 scripts/manage_secret.py list                # list all secret keys
python3 scripts/manage_secret.py get <key>           # print a secret's value
```

Keys follow a `<service>_<name>` convention (e.g. `uneventful_twilio_auth_token`,
`partyfoal_resend_api_key`) so they're easy to find and reference from playbook
`vars_files: [../../secrets.yml]` as `{{ <key> }}` in compose templates.

Requires `ansible-vault` and the vault password file configured in `ansible.cfg`
(`vault_password_file = .vault_pass`).
