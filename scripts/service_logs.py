#!/usr/bin/env python3
"""
Get logs for a service running in Docker.
Finds the host where the service is running and tails the logs.
"""

import subprocess
import sys
from pathlib import Path

import yaml


def load_config():
    """Load services configuration."""
    root = Path(__file__).parent.parent

    services = []

    # Load services.yaml
    services_file = root / "config" / "services.yaml"
    if services_file.exists():
        with open(services_file) as f:
            data = yaml.safe_load(f)
            services = data.get("services", [])

    # Load inventory to get host mapping
    inventory_file = root / "inventory.yaml"
    hosts = {}
    if inventory_file.exists():
        with open(inventory_file) as f:
            data = yaml.safe_load(f)
            # Extract all hosts from all groups
            for group_name, group_data in data.items():
                if isinstance(group_data, dict) and "hosts" in group_data:
                    for host, host_data in group_data["hosts"].items():
                        if isinstance(host_data, dict) and "ansible_host" in host_data:
                            hosts[host] = host_data["ansible_host"]

    return services, hosts


def find_service_host(service_name, services, hosts):
    """Find which host a service is running on and the service directory."""
    # Build a dict of stacks from services with stack attribute
    stacks = {}
    for service in services:
        if "stack" in service:
            stack_name = service["stack"]
            if stack_name not in stacks:
                stacks[stack_name] = {
                    "name": stack_name,
                    "machine": service.get("machine"),
                    "path": service.get("path", f"/opt/{stack_name}"),
                }

    # Check compose stacks first (exact match)
    if service_name.lower() in stacks:
        stack = stacks[service_name.lower()]
        machine_ip = stack.get("machine")
        service_dir = stack.get("path")
        # Find hostname from IP
        for hostname, ip in hosts.items():
            if ip == machine_ip:
                return hostname, service_dir

    # Check individual services (exact match)
    for service in services:
        if service["name"].lower() == service_name.lower():
            machine_ip = service.get("machine")
            # Use the path if provided, otherwise guess from stack or service name
            if "path" in service:
                service_dir = service["path"]
            elif "stack" in service:
                service_dir = service.get("path", f"/opt/{service['stack']}")
            else:
                service_dir = f"/opt/{service_name.lower()}"
            # Find hostname from IP
            for hostname, ip in hosts.items():
                if ip == machine_ip:
                    return hostname, service_dir

    return None, None


def main():
    if len(sys.argv) < 2:
        print("Usage: service_logs.py <service_name>", file=sys.stderr)
        sys.exit(1)

    service_name = sys.argv[1]
    services, hosts = load_config()

    # Find which host the service is on
    hostname, service_dir = find_service_host(service_name, services, hosts)

    if not hostname:
        print(f"Error: Could not determine host for service '{service_name}'", file=sys.stderr)
        print("\nAvailable services:", file=sys.stderr)

        # Show available stacks
        stacks = {}
        for service in services:
            if "stack" in service:
                stacks[service["stack"]] = True

        if stacks:
            print("\nCompose stacks:", file=sys.stderr)
            for stack_name in sorted(stacks.keys()):
                print(f"  - {stack_name}", file=sys.stderr)

        # Show available services
        if services:
            print("\nIndividual services:", file=sys.stderr)
            service_names = set(s['name'] for s in services)
            for name in sorted(service_names):
                print(f"  - {name}", file=sys.stderr)

        sys.exit(1)

    if not service_dir:
        service_dir = f"/opt/{service_name}"

    print(f"Fetching logs for '{service_name}' from {hostname}.fg")
    print(f"Service directory: {service_dir}")
    print("-" * 60)

    # Build command to cd to service directory and run docker compose logs
    docker_cmd = f"cd {service_dir} && docker compose logs -f --tail 50"

    # Use SSH directly with .fg suffix
    ssh_cmd = [
        "ssh",
        "-t",  # Force pseudo-terminal for interactive logs
        f"{hostname}.fg",
        docker_cmd,
    ]

    try:
        result = subprocess.run(ssh_cmd)
        sys.exit(result.returncode)
    except KeyboardInterrupt:
        print("\nStopped following logs")
        sys.exit(0)


if __name__ == "__main__":
    main()
