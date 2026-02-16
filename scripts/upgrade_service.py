#!/usr/bin/env python3
"""
Upgrade a service's Docker image to the latest version.
Updates the compose template file with the new image tag.
"""

import re
import sys
from pathlib import Path

import requests


def parse_image(image_str):
    """Parse an image string into registry, repo, and tag."""
    # Remove digest if present
    image_str = image_str.split("@")[0]

    # Default values
    registry = "docker.io"
    tag = "latest"

    # Check for tag
    if ":" in image_str.split("/")[-1]:
        image_str, tag = image_str.rsplit(":", 1)

    # Parse registry
    parts = image_str.split("/")
    if len(parts) >= 2 and ("." in parts[0] or ":" in parts[0]):
        registry = parts[0]
        repo = "/".join(parts[1:])
    elif len(parts) == 1:
        # Official Docker Hub image
        registry = "docker.io"
        repo = f"library/{parts[0]}"
    else:
        registry = "docker.io"
        repo = "/".join(parts)

    return registry, repo, tag


def parse_version(tag):
    """Parse a version tag into sortable components."""
    # Remove 'v' prefix
    tag = tag.lstrip("v")
    # Split by common delimiters
    parts = re.split(r"[.\-]", tag)
    result = []
    for p in parts:
        if p.isdigit():
            result.append((0, int(p)))  # Numbers sort first
        else:
            result.append((1, p))  # Strings sort after
    return result


def is_valid_version_tag(tag):
    """Check if a tag looks like a clean semantic version."""
    # Skip tags with architecture prefixes
    if re.match(r"^(arm|amd|x86|linux|windows)", tag, re.I):
        return False
    # Skip tags with "version-" prefix (linuxserver old format)
    if tag.startswith("version-"):
        return False
    # Skip tags with build metadata that's too long
    if re.search(r"\d{8,}", tag):  # Long numbers like timestamps
        return False
    # Must start with a digit or 'v' followed by digit
    if not re.match(r"^v?\d", tag):
        return False
    # Basic semver pattern: X.Y or X.Y.Z (no suffix for cleaner versions)
    if re.match(r"^v?\d+\.\d+(\.\d+)?$", tag):
        return True
    # LinuxServer pattern: X.Y.Z-lsNNN
    if re.match(r"^v?\d+\.\d+(\.\d+)?-ls\d+$", tag):
        return True
    return False


def get_docker_hub_latest(repo):
    """Get latest tag from Docker Hub."""
    url = f"https://hub.docker.com/v2/repositories/{repo}/tags"
    params = {"page_size": 100}

    try:
        resp = requests.get(url, params=params, timeout=10)
        resp.raise_for_status()
        data = resp.json()

        tags = [t["name"] for t in data.get("results", [])]

        # Filter to valid version tags
        version_tags = [t for t in tags if is_valid_version_tag(t)]

        if version_tags:
            # Sort by version number descending
            version_tags.sort(key=parse_version, reverse=True)
            return version_tags[0]
        elif "latest" in tags:
            return "latest"
        elif tags:
            return tags[0]
    except Exception as e:
        print(f"  Warning: Could not query Docker Hub: {e}", file=sys.stderr)

    return None


def get_ghcr_latest(repo):
    """Get latest tag from GitHub Container Registry."""
    # GHCR requires token for public repos too
    url = f"https://ghcr.io/v2/{repo}/tags/list"

    try:
        # Get anonymous token
        token_url = f"https://ghcr.io/token?scope=repository:{repo}:pull"
        token_resp = requests.get(token_url, timeout=10)
        token_resp.raise_for_status()
        token = token_resp.json().get("token")

        headers = {"Authorization": f"Bearer {token}"}
        resp = requests.get(url, headers=headers, timeout=10)
        resp.raise_for_status()
        data = resp.json()

        tags = data.get("tags", [])

        # Filter to valid version tags
        version_tags = [t for t in tags if is_valid_version_tag(t)]

        if version_tags:
            version_tags.sort(key=parse_version, reverse=True)
            return version_tags[0]
        elif "latest" in tags:
            return "latest"
        elif "release" in tags:
            return "release"
        elif tags:
            return sorted(tags)[-1]
    except Exception as e:
        print(f"  Warning: Could not query GHCR: {e}", file=sys.stderr)

    return None


def get_lscr_latest(repo):
    """Get latest tag from LinuxServer Container Registry."""
    # LSCR mirrors to GHCR
    ghcr_repo = f"linuxserver/{repo.split('/')[-1]}"
    return get_ghcr_latest(ghcr_repo)


def get_latest_tag(registry, repo, current_tag):
    """Get the latest tag for an image."""
    if registry == "docker.io":
        return get_docker_hub_latest(repo)
    elif registry == "ghcr.io":
        return get_ghcr_latest(repo)
    elif registry == "lscr.io":
        return get_lscr_latest(repo)
    else:
        print(f"  Warning: Unknown registry {registry}", file=sys.stderr)
        return None


def find_compose_template(service_name, templates_dir):
    """Find the compose template for a service."""
    patterns = [
        f"{service_name}-compose.yml.j2",
        f"{service_name}.compose.yml.j2",
        f"{service_name}-compose.yaml.j2",
        f"{service_name}.compose.yaml.j2",
    ]

    for pattern in patterns:
        path = templates_dir / pattern
        if path.exists():
            return path

    # Try fuzzy match
    for f in templates_dir.glob("*compose*.j2"):
        if service_name.replace("_", "-") in f.name or service_name.replace("-", "_") in f.name:
            return f

    return None


def main():
    if len(sys.argv) < 2:
        print("Usage: upgrade_service.py <service_name>", file=sys.stderr)
        sys.exit(1)

    service_name = sys.argv[1]
    root = Path(__file__).parent.parent
    templates_dir = root / "templates"

    # Find compose file
    compose_file = find_compose_template(service_name, templates_dir)
    if not compose_file:
        print(f"Error: Could not find compose template for '{service_name}'", file=sys.stderr)
        print(f"Available templates:", file=sys.stderr)
        for f in sorted(templates_dir.glob("*compose*.j2")):
            name = f.name.replace("-compose.yml.j2", "").replace(".compose.yml.j2", "")
            print(f"  {name}", file=sys.stderr)
        sys.exit(1)

    print(f"File: {compose_file.name}")

    # Read file
    content = compose_file.read_text()

    # Find all image lines
    image_pattern = re.compile(r'^(\s*image:\s*)([^\s#]+)', re.MULTILINE)
    matches = list(image_pattern.finditer(content))

    if not matches:
        print("No image tags found in compose file")
        sys.exit(0)

    updates = []
    for match in matches:
        prefix = match.group(1)
        image_str = match.group(2)

        registry, repo, current_tag = parse_image(image_str)

        # Skip images with SHA digests (pinned for a reason)
        if "@sha256:" in match.group(2):
            print(f"  {repo}: skipped (pinned with digest)")
            continue

        latest_tag = get_latest_tag(registry, repo, current_tag)

        if latest_tag is None:
            print(f"  {repo}:{current_tag}: could not determine latest")
            continue

        if latest_tag == current_tag:
            print(f"  {repo}:{current_tag}: already latest")
            continue

        # Build new image string
        if registry == "docker.io" and not repo.startswith("library/"):
            new_image = f"{repo}:{latest_tag}"
        elif registry == "docker.io":
            new_image = f"{repo.replace('library/', '')}:{latest_tag}"
        else:
            new_image = f"{registry}/{repo}:{latest_tag}"

        print(f"  {repo}: {current_tag} -> {latest_tag}")
        updates.append((match.start(), match.end(), f"{prefix}{new_image}"))

    if not updates:
        print("\nNo updates available")
        sys.exit(0)

    # Apply updates in reverse order to preserve positions
    for start, end, replacement in reversed(updates):
        content = content[:start] + replacement + content[end:]

    compose_file.write_text(content)
    print(f"\nUpdated {compose_file.name}")


if __name__ == "__main__":
    main()
