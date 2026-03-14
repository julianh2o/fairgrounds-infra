# fairgrounds-infra
Infrastructure for the fairgrounds

# TODO
* create Calcifer VM for home assistant
* clean up home assistant scenes to fix those lights and the govee strings
* figure out clean way of setting the lights in home assistant
* need a way to add information (contact methods) to users on outreach
* make outreach display better on mobile devices
* move more data into outreach
* finish configuring readarr
* continue using claude to generate content for outreach
* more work on grafana dashboards
* create a good CPU/memory chart for the VM children under the host parent.. These should be colocated and intuitive to show where the resources are going.
* We can do this CPU/memory chart for both proxmox and truenas
* It would be great to have a similar network chart that we can weigh against our Gigabit connection. eg..  a way to see how much of our total bandwidth is being used.
* install uptime kuma: https://github.com/louislam/uptime-kuma
* add server and service status to home assistant dashboard
* Move plex to Ceto
* Move ollama to ceto
* Move ollama to Ceto
* Move homeassistant to a new proxmox VM
* decommmission truenas version of homeassistant
* create local database server

# Managing Secrets

Secrets are stored in `secrets.yml` encrypted with ansible-vault.

```bash
# Edit secrets
ansible-vault edit secrets.yml

# View secrets
ansible-vault view secrets.yml

# Generate a random password
openssl rand -base64 32

# Add a new secret with a random password
ansible-vault decrypt secrets.yml && echo "my_secret: $(openssl rand -base64 32)" >> secrets.yml && ansible-vault encrypt secrets.yml
```

Required secrets:
- `kopia_server_password` - Kopia web UI password
- `kopia_repository_password` - Kopia repository encryption password



# Run Script

The `./run` script is a launcher for commands defined in `scripts.yaml`. It supports nested command organization and argument passing.

## Usage

```bash
# List top-level categories and commands
./run

# List subcommands within a category
./run services

# Run a specific command
./run ping
./run services deploy caddy
./run services deploy-all

# Pass additional arguments after --
./run ping -- --limit melinoe

# Commands with required arguments (use $1, $2 in scripts.yaml)
./run services deploy caddy        # $1 = caddy
./run services logs grafana        # $1 = grafana
./run setup import_new_vm myhost   # $1 = myhost
```

## Available Command Categories

| Category | Description |
|----------|-------------|
| `ping` | Test connectivity to all hosts |
| `apt_upgrade` | Update packages on all hosts |
| `services` | Service deployment and management commands |
| `setup` | Infrastructure setup commands |
| `monitor` | Monitoring and diagnostic commands |
| `maintenance` | Maintenance and backup commands |

## Adding Commands

Commands are defined in `scripts.yaml`. Each command has a `name` (description) and `cmd` (shell command to run). Commands can be nested into categories. Use `$1`, `$2`, etc. as placeholders for positional arguments.

```yaml
scripts:
  mycommand:
    name: Description of my command
    cmd: ansible-playbook playbooks/my_playbook.yaml

  mycategory:
    name: Category description
    subcommand:
      name: Run something with $1
      cmd: ansible-playbook playbooks/do_thing.yaml --limit $1
```
