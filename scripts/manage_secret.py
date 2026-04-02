#!/usr/bin/env python3
"""
Manage secrets in the encrypted secrets.yml file.

Usage:
    manage_secret.py new <key> [value]   - Add a new secret (generates random value if not provided)
    manage_secret.py list                - List all secret keys
    manage_secret.py get <key>           - Get a secret value
"""

import secrets as secrets_module
import subprocess
import sys
import base64
from pathlib import Path

import yaml


def get_secrets_path():
    """Get path to secrets.yml."""
    return Path(__file__).parent.parent / "secrets.yml"


def decrypt_secrets():
    """Decrypt and return secrets content."""
    secrets_path = get_secrets_path()
    result = subprocess.run(
        ["ansible-vault", "view", str(secrets_path)],
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        print(f"Error decrypting secrets: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    return result.stdout


def encrypt_secrets(content):
    """Encrypt and write secrets content."""
    secrets_path = get_secrets_path()

    # Write to temp file, then encrypt in place
    temp_path = secrets_path.with_suffix(".yml.tmp")
    temp_path.write_text(content)

    result = subprocess.run(
        ["ansible-vault", "encrypt", str(temp_path)],
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        temp_path.unlink()
        print(f"Error encrypting secrets: {result.stderr}", file=sys.stderr)
        sys.exit(1)

    # Move temp to original
    temp_path.rename(secrets_path)


def generate_random_value():
    """Generate a random base64 string suitable for encryption keys."""
    return base64.b64encode(secrets_module.token_bytes(32)).decode('ascii')


def cmd_new(args):
    """Add a new secret."""
    if len(args) < 1:
        print("Usage: manage_secret.py new <key> [value]", file=sys.stderr)
        sys.exit(1)

    key = args[0]
    value = args[1] if len(args) > 1 else generate_random_value()

    # Load existing secrets
    content = decrypt_secrets()
    data = yaml.safe_load(content)

    if data is None:
        data = {}

    if key in data:
        print(f"Error: Key '{key}' already exists. Use a different key or edit manually.", file=sys.stderr)
        sys.exit(1)

    # Add new key
    data[key] = value

    # Write back
    output = yaml.dump(data, default_flow_style=False, sort_keys=False)
    encrypt_secrets(output)

    print(f"Added secret: {key}")
    if len(args) < 2:
        print(f"Generated value: {value}")


def cmd_list(args):
    """List all secret keys."""
    content = decrypt_secrets()
    data = yaml.safe_load(content)

    if data is None:
        print("No secrets found")
        return

    print("Secret keys:")
    for key in sorted(data.keys()):
        print(f"  {key}")


def cmd_get(args):
    """Get a secret value."""
    if len(args) < 1:
        print("Usage: manage_secret.py get <key>", file=sys.stderr)
        sys.exit(1)

    key = args[0]

    content = decrypt_secrets()
    data = yaml.safe_load(content)

    if data is None or key not in data:
        print(f"Error: Key '{key}' not found", file=sys.stderr)
        sys.exit(1)

    print(data[key])


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    command = sys.argv[1]
    args = sys.argv[2:]

    commands = {
        "new": cmd_new,
        "list": cmd_list,
        "get": cmd_get,
    }

    if command not in commands:
        print(f"Unknown command: {command}", file=sys.stderr)
        print(__doc__)
        sys.exit(1)

    commands[command](args)


if __name__ == "__main__":
    main()
