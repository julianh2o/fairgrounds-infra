# Docker Service Role

A reusable Ansible role for deploying Docker Compose services with a consistent pattern.

## Overview

This role standardizes the deployment of Docker Compose services by:
- Creating service directories with proper permissions
- Deploying docker-compose.yml from templates
- Deploying additional configuration files
- Managing the Docker Compose lifecycle (pull, build, start, restart)

## Requirements

- `community.docker.docker_compose_v2` collection
- Docker and Docker Compose v2 installed on target hosts
- Ansible 2.9 or higher

## Role Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `service_name` | Name of the service (used for project name and directory) | `grafana` |
| `compose_template` | Path to docker-compose template (relative to templates/) | `grafana-compose.yml.j2` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `service_base_dir` | `/opt/{{ service_name }}` | Base directory for service files |
| `service_directories` | `[]` | Additional directories to create (see examples) |
| `config_files` | `[]` | Additional config files to deploy (see examples) |
| `docker_compose_state` | `restarted` | Docker Compose state (present, restarted, stopped) |
| `docker_compose_pull` | `always` | Pull policy (always, missing, never) |
| `docker_compose_build` | `never` | Build policy (always, never) |
| `service_owner` | `root` | Owner of service files |
| `service_group` | `root` | Group of service files |
| `service_dir_mode` | `0755` | Default directory permissions |
| `service_file_mode` | `0644` | Default file permissions |

## Examples

### Basic Service (Prometheus)

```yaml
- name: Deploy Prometheus
  hosts: melinoe
  become: yes

  roles:
    - role: docker_service
      vars:
        service_name: prometheus
        compose_template: prometheus.yml.j2
        config_files:
          - src: prometheus.config.yml.j2
            dest: config.yml
```

This creates:
```
/opt/prometheus/
├── docker-compose.yml
└── config.yml
```

### Service with Data Directory (Grafana)

```yaml
- name: Deploy Grafana
  hosts: melinoe
  become: yes

  roles:
    - role: docker_service
      vars:
        service_name: grafana
        compose_template: grafana-compose.yml.j2
        config_files:
          - src: grafana.ini.j2
            dest: grafana.ini
        service_directories:
          - path: data
            mode: "0777"
        docker_compose_state: present
```

This creates:
```
/opt/grafana/
├── docker-compose.yml
├── grafana.ini
└── data/  (mode 0777)
```

### Service with Custom Build

```yaml
- name: Deploy Custom Service
  hosts: melinoe
  become: yes

  roles:
    - role: docker_service
      vars:
        service_name: myapp
        compose_template: myapp-compose.yml.j2
        config_files:
          - src: myapp.env.j2
            dest: .env
          - src: myapp.config.json.j2
            dest: config.json
            mode: "0600"  # Sensitive config
        service_directories:
          - data
          - logs
          - path: uploads
            mode: "0777"
        docker_compose_build: always
        docker_compose_state: restarted
```

This creates:
```
/opt/myapp/
├── docker-compose.yml
├── .env
├── config.json (mode 0600)
├── data/
├── logs/
└── uploads/ (mode 0777)
```

### Service with Secrets

```yaml
- name: Deploy Service with Secrets
  hosts: melinoe
  become: yes
  vars_files:
    - ../secrets/vault_vars.yml

  roles:
    - role: docker_service
      vars:
        service_name: myapp
        compose_template: myapp-compose.yml.j2
        # Templates can reference vault_vars.yml variables
```

## Directory Structure

The role expects this repository structure:

```
.
├── playbooks/
│   └── deploy_myservice.yaml
├── templates/
│   ├── myservice-compose.yml.j2
│   └── myservice.config.j2
└── roles/
    └── docker_service/
        ├── defaults/
        │   └── main.yml
        ├── tasks/
        │   └── main.yml
        └── README.md
```

## Usage in Playbooks

1. Create a docker-compose template in `templates/`:
   ```yaml
   # templates/myservice-compose.yml.j2
   services:
     myservice:
       image: myimage:latest
       ports:
         - 8080:8080
       restart: always
   ```

2. Create additional config templates as needed:
   ```ini
   # templates/myservice.conf.j2
   [settings]
   port = 8080
   ```

3. Create a playbook:
   ```yaml
   # playbooks/deploy_myservice.yaml
   - name: Deploy My Service
     hosts: melinoe
     become: yes

     roles:
       - role: docker_service
         vars:
           service_name: myservice
           compose_template: myservice-compose.yml.j2
           config_files:
             - src: myservice.conf.j2
               dest: config.conf
   ```

4. Run the playbook:
   ```bash
   ansible-playbook playbooks/deploy_myservice.yaml
   ```

## Advanced: Multiple Services in One Playbook

```yaml
- name: Deploy monitoring stack
  hosts: melinoe
  become: yes

  tasks:
    - include_role:
        name: docker_service
      vars:
        service_name: prometheus
        compose_template: prometheus.yml.j2
        config_files:
          - src: prometheus.config.yml.j2
            dest: config.yml

    - include_role:
        name: docker_service
      vars:
        service_name: grafana
        compose_template: grafana-compose.yml.j2
        config_files:
          - src: grafana.ini.j2
            dest: grafana.ini
        service_directories:
          - path: data
            mode: "0777"
```

## Files Created on Target Host

For each service deployment, the role creates:

```
{{ service_base_dir }}/          # Default: /opt/{{ service_name }}/
├── docker-compose.yml           # Always created
├── {{ config_files[].dest }}    # If config_files specified
└── {{ service_directories }}/   # If service_directories specified
```

## Author

Created for the fairgrounds infrastructure project.
