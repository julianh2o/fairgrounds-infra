#!/usr/bin/env python3
"""
Sync Terraform state with an ansible-vault encrypted copy tracked in git.

The plaintext terraform/terraform.tfstate stays gitignored (it contains
secrets). terraform/state.vault is the encrypted copy that gets committed.

Usage:
    tfstate.py pull [--force]   - Decrypt state.vault to terraform.tfstate
    tfstate.py push [--force]   - Encrypt terraform.tfstate to state.vault

Both commands refuse to replace newer state with older state (compared by
the state file's "serial") unless --force is given. Always pull before you
run terraform, and push after.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
STATE_PATH = REPO_ROOT / "terraform" / "terraform.tfstate"
VAULT_PATH = REPO_ROOT / "terraform" / "state.vault"


def run_vault(*args):
    """Run ansible-vault from the repo root so ansible.cfg supplies the password file."""
    result = subprocess.run(
        ["ansible-vault", *args],
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
    )
    if result.returncode != 0:
        print(f"ansible-vault {args[0]} failed: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    return result.stdout


def write_private(path, content):
    """Write a file readable only by the current user."""
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(content)


def parse_state(content, label):
    try:
        return json.loads(content)
    except json.JSONDecodeError as e:
        print(f"Error: {label} is not valid JSON: {e}", file=sys.stderr)
        sys.exit(1)


def decrypt_vault():
    return run_vault("view", str(VAULT_PATH))


def cmd_pull(args):
    """Decrypt the vault copy into terraform.tfstate."""
    force = "--force" in args

    if not VAULT_PATH.exists():
        print(f"Error: {VAULT_PATH} not found. Run 'push' first.", file=sys.stderr)
        sys.exit(1)

    content = decrypt_vault()
    remote = parse_state(content, "state.vault")

    if STATE_PATH.exists():
        local = parse_state(STATE_PATH.read_text(), "local terraform.tfstate")
        if local == remote:
            print("Already up to date")
            return
        if local.get("serial", 0) > remote.get("serial", 0) and not force:
            print(
                f"Error: local state (serial {local['serial']}) is newer than "
                f"state.vault (serial {remote.get('serial', 0)}). "
                "Run 'push' to save it, or use --force to overwrite it.",
                file=sys.stderr,
            )
            sys.exit(1)
        backup = STATE_PATH.with_name("terraform.tfstate.pre-pull.backup")
        write_private(backup, STATE_PATH.read_text())
        print(f"Saved previous local state to {backup.name}")

    write_private(STATE_PATH, content)
    print(f"Pulled state (serial {remote.get('serial', 0)})")


def cmd_push(args):
    """Encrypt terraform.tfstate into the vault copy."""
    force = "--force" in args

    if not STATE_PATH.exists():
        print(f"Error: {STATE_PATH} not found. Run 'pull' first.", file=sys.stderr)
        sys.exit(1)

    local = parse_state(STATE_PATH.read_text(), "local terraform.tfstate")

    if VAULT_PATH.exists():
        remote = parse_state(decrypt_vault(), "state.vault")
        if local == remote:
            print("Already up to date")
            return
        if remote.get("serial", 0) > local.get("serial", 0) and not force:
            print(
                f"Error: state.vault (serial {remote.get('serial', 0)}) is newer than "
                f"local state (serial {local.get('serial', 0)}). "
                "Run 'pull' first, or use --force to overwrite it.",
                file=sys.stderr,
            )
            sys.exit(1)

    # Encrypt a temp copy, then move it into place so a failure never
    # leaves a half-written vault file.
    temp_path = VAULT_PATH.with_name("state.vault.tmp")
    write_private(temp_path, STATE_PATH.read_text())
    try:
        run_vault("encrypt", str(temp_path))
    except SystemExit:
        temp_path.unlink(missing_ok=True)
        raise
    temp_path.replace(VAULT_PATH)
    print(f"Pushed state (serial {local.get('serial', 0)}) to {VAULT_PATH.name}")


COMMANDS = {"pull": cmd_pull, "push": cmd_push}


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(__doc__)
        sys.exit(1)
    COMMANDS[sys.argv[1]](sys.argv[2:])


if __name__ == "__main__":
    main()
