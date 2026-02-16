#!/usr/bin/env python3
"""
Display service architecture grouped by host.
Reads from inventory.yaml and config/services.yaml.
"""

import sys
from collections import defaultdict
from pathlib import Path

import yaml


def load_yaml(path):
    with open(path) as f:
        return yaml.safe_load(f)


def main():
    root = Path(__file__).parent.parent

    # Load inventory
    inventory = load_yaml(root / "inventory.yaml")

    # Build IP -> host info mapping
    ip_to_host = {}
    for group_name, group_data in inventory.items():
        if group_name == "all":
            continue
        if not isinstance(group_data, dict) or "hosts" not in group_data:
            continue
        for hostname, host_data in group_data["hosts"].items():
            ip = host_data.get("ansible_host", "")
            desc = host_data.get("description", "")
            ip_to_host[ip] = {"name": hostname, "description": desc, "ip": ip}

    # Load services
    services_data = load_yaml(root / "config" / "services.yaml")
    services = services_data.get("services", [])

    # Group services by host IP
    services_by_ip = defaultdict(list)
    for svc in services:
        ip = svc.get("machine", "")
        services_by_ip[ip].append(svc)

    # Sort hosts by IP
    sorted_ips = sorted(ip_to_host.keys(), key=lambda x: [int(p) for p in x.split(".")])

    # Display
    for ip in sorted_ips:
        host = ip_to_host[ip]
        host_services = services_by_ip.get(ip, [])

        # Header
        print(f"\033[1;36m{host['name'].upper()}\033[0m ({ip})")
        if host["description"]:
            print(f"  {host['description']}")
        print()

        if not host_services:
            print("  \033[90m(no services)\033[0m")
            print()
            continue

        # Sort services by name
        host_services.sort(key=lambda s: s.get("name", "").lower())

        # Calculate column widths
        name_width = max(len(s.get("name", "")) for s in host_services)
        url_width = max(len(s.get("url", "")) for s in host_services)

        # Table header
        print(f"  \033[1m{'Service':<{name_width}}  {'URL':<{url_width}}  Description\033[0m")
        print(f"  {'-' * name_width}  {'-' * url_width}  {'-' * 30}")

        # Services
        for svc in host_services:
            name = svc.get("name", "")
            url = svc.get("url", "")
            desc = svc.get("description", "")
            print(f"  {name:<{name_width}}  {url:<{url_width}}  {desc}")

        print()


if __name__ == "__main__":
    main()
