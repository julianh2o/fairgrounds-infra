#!/bin/bash
# Script to download favicons for all services

FAVICON_DIR="$(dirname "$0")/favicons"

# Function to download favicon from a URL
download_favicon() {
    local service_name="$1"
    local url="$2"
    local output_file="${FAVICON_DIR}/${service_name}.png"

    echo "Downloading favicon for ${service_name} from ${url}..."

    # Try to fetch the favicon using DuckDuckGo's favicon service (returns PNG)
    curl -s -o "$output_file" "https://icons.duckduckgo.com/ip3/${url}.ico"

    if [ -s "$output_file" ]; then
        echo "✓ Downloaded ${service_name}"
    else
        echo "✗ Failed to download ${service_name}"
        rm -f "$output_file"
    fi
}

# Download favicons for well-known services
download_favicon "audiobookshelf" "audiobookshelf.org"
download_favicon "deluge" "deluge-torrent.org"
download_favicon "grafana" "grafana.com"
download_favicon "home-assistant" "home-assistant.io"
download_favicon "immich" "immich.app"
download_favicon "jackett" "github.com"  # Jackett doesn't have its own site
download_favicon "nzbhydra" "github.com"
download_favicon "ollama" "ollama.com"
download_favicon "ombi" "ombi.io"
download_favicon "proxmox" "proxmox.com"
download_favicon "prometheus" "prometheus.io"
download_favicon "qbittorrent" "qbittorrent.org"
download_favicon "radarr" "radarr.video"
download_favicon "readarr" "readarr.com"
download_favicon "sabnzbd" "sabnzbd.org"
download_favicon "sonarr" "sonarr.tv"
download_favicon "tautulli" "tautulli.com"
download_favicon "truenas" "truenas.com"

echo ""
echo "Download complete! Favicons saved to ${FAVICON_DIR}"
echo "Total favicons: $(ls -1 ${FAVICON_DIR}/*.png 2>/dev/null | wc -l)"
