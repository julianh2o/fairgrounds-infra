# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Instructions
IMPORTANT: You must ask for explicit permission to run any SSH commands and any commands that might cause any changes should simply be displayed for the user to run themself
IMPORTANT: You must always ask for explicit permission to run any playbook
IMPORTANT: After tasks or plans that take more than a few seconds, use the notify utility to get the user's attention

## Repository Overview

This is an Ansible-based infrastructure management repository for "fairgrounds" - a personal infrastructure setup managing multiple Linux hosts with monitoring, reverse proxy, and various services.

## Key Commands

### Initial Setup

```bash
# One-time setup: Create ansible service account on all hosts
# Use -k if host requires SSH password, -K for sudo password
ansible-playbook playbooks/setup/ansible_user.yaml -u julian -k -K
```

### Ansible Operations

```bash
# Test connectivity to all hosts
ansible-playbook playbooks/ping.yaml

# Update packages on hosts
ansible-playbook playbooks/update.yaml

# Deploy all services at once
ansible-playbook playbooks/deploy_all_services.yaml

# Deploy individual services
ansible-playbook playbooks/services/deploy_caddy.yaml
ansible-playbook playbooks/services/deploy_prometheus.yaml
ansible-playbook playbooks/services/deploy_grafana.yaml
ansible-playbook playbooks/services/deploy_myflix.yaml
ansible-playbook playbooks/services/deploy_immich.yaml
ansible-playbook playbooks/services/deploy_rreading_glasses.yaml
ansible-playbook playbooks/services/deploy_uneventful.yaml
ansible-playbook playbooks/services/deploy_tautulli.yaml
ansible-playbook playbooks/services/deploy_discord_ollama.yaml
ansible-playbook playbooks/services/deploy_rclone_to_backblaze.yaml

# Deploy monitoring stack
ansible-playbook playbooks/setup/node_exporter.yml

# Update Caddy reverse proxy configuration
ansible-playbook playbooks/check_services.yaml

# Deploy GitHub keys puller
ansible-playbook playbooks/setup/github_keys_puller.yml

# Install Ansible dependencies (roles and collections)
ansible-galaxy install -r requirements.yaml
```

### Working with Specific Hosts

```bash
# Target specific host groups defined in inventory.yaml
ansible-playbook playbooks/ping.yaml --limit melinoe
ansible-playbook playbooks/ping.yaml --limit linuxhosts
```

## Architecture

### Infrastructure Layout

**Host Groups** (defined in `inventory.yaml`):
- `linuxhosts`: Main Linux servers (melinoe, truenas)
- `otherhosts`: Additional hosts accessed via IP (kvasir)

**Primary Host**: `melinoe` - main deployment target for services

### Service Deployment Pattern

Services are deployed as Docker Compose applications following this pattern:
1. Templates in `templates/` define Jinja2 templates for docker-compose files and configs
2. Playbooks deploy templates to `/opt/<service>/` on target hosts
3. Docker Compose starts/restarts services using `community.docker.docker_compose_v2` module

**Deployed Services**:
- **Caddy** (`/opt/caddy/`) - Reverse proxy with automatic HTTPS (Let's Encrypt) on ports 80/443
- **Prometheus** (`/opt/prometheus/`) - Metrics collection on port 9090
- **Grafana** (`/opt/grafana/`) - Metrics visualization
- **Node Exporter** - System metrics exporter (via geerlingguy.node_exporter role)

### Reverse Proxy Configuration

Caddy is used as the reverse proxy with automatic HTTPS via Let's Encrypt:

**Service Configuration** (`config/services.yaml`):
- Each service entry contains:
  - `name`: Full DNS hostname (e.g., `audiobookshelf.julianverse.net`, `books.julianhartline.com`)
  - `machine`: Backend server IP address
  - `port`: Backend service port
- Supports multiple domains (julianverse.net, bawdyshop.space, julianhartline.com)
- Same backend service can have multiple DNS names for different domains

**Deployment**:
- `templates/caddy.j2` generates Caddyfile with all proxy entries
- `playbooks/deploy_caddy.yaml` deploys Caddy as a Docker Compose service to `/opt/caddy/`
- Caddy automatically obtains and renews SSL certificates from Let's Encrypt
- Certificate data is persisted in `/opt/caddy/data/` directory

### SSH Configuration

**Ansible Configuration** (`ansible.cfg`):
- Default inventory: `inventory.yaml` (no need for `-i` flag)
- Default remote user: `ansible` (override with `-u` flag when needed)
- Custom SSH config via `ssh.config` file
- SSH multiplexing enabled for performance (`ControlMaster`, `ControlPersist`)
- SSH pipelining enabled for faster execution

### User Management

**Ansible Service Account**:
- Dedicated `ansible` user for all automation tasks
- Configured with passwordless sudo via `/etc/sudoers.d/ansible`
- Member of `docker` group for container management
- Uses SSH key authentication from `secrets/id_ed25519.pub`
- Set up via `playbooks/setup/ansible_user.yaml` (run once with `-u julian -K`)

## File Organization

- `playbooks/` - Ansible playbooks for various deployment and management tasks
- `templates/` - Jinja2 templates for service configurations and compose files
- `config/` - Configuration data files (e.g., services.yaml for proxy definitions)
- `myroles/` - Custom Ansible roles (committed to repository)
- `roles/` - Downloaded Ansible Galaxy roles (gitignored, install with `ansible-galaxy install -r requirements.yaml`)
- `inventory.yaml` - Ansible inventory defining hosts and groups
- `requirements.yaml` - Ansible Galaxy dependencies (collections and roles)
- `ansible.cfg` - Ansible configuration with SSH settings and roles_path
- `ssh.config` - Custom SSH configuration for host connections
- `secrets/` - SSH keys for authentication
- `archive/` - Old/deprecated configurations (Terraform, etc.)

## Important Notes

- All service deployments use `become: yes` to run with sudo privileges
- Docker Compose v2 plugin is required (`community.docker.docker_compose_v2`)
- Service templates are deployed to `/opt/<service>/` directories on target hosts
- The Caddy template dynamically generates proxy entries from `config/services.yaml`
- Ansible Galaxy collections required: `grafana.grafana`
- Ansible Galaxy roles required: `geerlingguy.node_exporter`
