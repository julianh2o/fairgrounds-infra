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
