
# CLAUDE.md

## Instructions

- Ask for explicit permission before running SSH commands or playbooks
- Use `./run` instead of `ansible-playbook` directly

## Repository Overview

Ansible-based infrastructure repo managing Linux VMs with Docker Compose services, monitoring, and Caddy reverse proxy.

## Commands

```bash
./run                              # List all available commands
./run services deploy <name>       # Deploy a service
./run services list                # Show services grouped by host
./run services refresh             # Refresh caddy, pihole, dashboard
./run ping                         # Test host connectivity
./run apt_upgrade                  # Update packages on all hosts
```

Use `-- --limit <host>` to target specific hosts.

## Architecture

**Hosts** (see `inventory.yaml`): VMs are ceto, metis, europa, daphne, arethusa. Bare metal includes truenas and njord (Proxmox).

**Service deployment**: Docker Compose via the `docker_service` role. Templates deploy to `/opt/<service>/` on target hosts.

**Reverse proxy**: Caddy with automatic HTTPS. Service definitions in `config/services.yaml` generate the Caddyfile.

## Adding a New Service

1. `templates/<service>-compose.yml.j2` - Docker Compose template
2. `playbooks/services/deploy_<service>.yaml` - Playbook using `docker_service` role
3. `config/services.yaml` - Caddy reverse proxy entry (if web-accessible)
4. `playbook_triggers.yml` - CI trigger paths
5. `playbooks/deploy_all_services.yaml` - Include in full deployments

## File Organization

- `playbooks/` - Ansible playbooks
- `templates/` - Jinja2 templates for compose files and configs
- `config/` - Configuration data (services.yaml for proxy definitions)
- `roles/` - Custom Ansible roles
- `scripts/` - Helper scripts used by `./run`
- `inventory.yaml` - Host definitions
- `secrets.yml` - Encrypted secrets (ansible-vault)
