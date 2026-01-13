# Service Architecture

### 192.168.0.105 (Njord)
- Proxmox (bare metal hypervisor)

### 192.168.0.10 (Ceto on Njord)
GPU-enabled workhorse for compute-intensive tasks.
- **immich** - Photo management (photos.julianhartline.com)
- **myalpr** - License plate recognition

### 192.168.0.11 (Metis on Njord)
General purpose VM.
- **grafana** - Metrics dashboards
- **prometheus** - Metrics collection
- **dashboard** - Infrastructure overview

### 192.168.0.12 (Europa on Njord)
Lightweight and high-availability services.
- **pihole** - DNS server with ad blocking

### 192.168.0.100 (Truenas)
- TrueNAS web UI (bare metal NAS)

### 192.168.0.203 (Melinoe on Truenas)
- **myflix** - Media automation
- **uneventful** - Bawdy Shop Events
- **fair-map** - Fairgrounds map
- **caddy** - Reverse proxy
- **discord-ollama** - Discord LLM bot
- **rclone-to-backblaze** - Backup sync

### 192.168.0.110 (on Truenas)
- Home Assistant

### 192.168.0.66 (Kvasir)
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
