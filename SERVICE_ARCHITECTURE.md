# Service Architecture

### 10.10.0.5 (Njord)
- Proxmox (bare metal hypervisor)

### 10.10.0.10 (Ceto on Njord)
GPU-enabled workhorse for compute-intensive tasks.
- **immich** - Photo management (photos.julianhartline.com)
- **myalpr** - License plate recognition

### 10.10.0.11 (Metis on Njord)
General purpose VM.
- **grafana** - Metrics dashboards
- **prometheus** - Metrics collection
- **dashboard** - Infrastructure overview
- **myflix** - Media automation
- **rclone-to-backblaze** - Backup sync
- **fair-map** - Fairgrounds map
- **uneventful** - Bawdy Shop Events
- **discord-ollama** - Discord bot with Ollama LLM
- **caddy** - Reverse proxy

### 10.10.0.12 (Europa on Njord)
Lightweight and high-availability services.
- **pihole** - DNS server with ad blocking

### 10.10.0.13 (Daphne on Njord)
Unassigned

### 10.10.0.14 (Arethusa on Njord)
Development Sandbox

### 10.10.0.6 (Truenas)
- TrueNAS web UI (bare metal NAS)

### 10.10.0.30 (Home Assistant on Truenas)
- Home Assistant

### 10.10.0.40 (Kvasir)
- **speaches** - Speech-to-text/TTS (whisper.julianverse.net)
- **ollama** - LLM API (no stack, standalone)
- **comfyui** - AI art
- **Plex** - Plex Media Center

## Domains

| Domain | Services |
|--------|----------|
| julianverse.net | dashboard, grafana, prometheus, whisper, ollama, map, home, myflix stack, truenas |
| julianhartline.com | books, photos, plex |
| bawdyshop.space | uneventful |
