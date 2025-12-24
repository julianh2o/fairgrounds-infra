# Secrets Management

This directory contains encrypted secrets for the infrastructure.

## Files

- **`vault_vars.yml`** - Encrypted variables (API tokens, emails, etc.)
  - Uses inline encryption with `ansible-vault encrypt_string`
  - Safe to commit to git
  - Automatically decrypted when playbooks run

- **`id_ed25519.vault`** - Encrypted SSH private key
  - File-level encryption with `ansible-vault encrypt`
  - Safe to commit to git
  - Decrypt to use: `ansible-vault view id_ed25519.vault > id_ed25519`

- **`id_ed25519.pub`** - SSH public key
  - Not secret, safe to commit

- **`id_ed25519`** - Decrypted SSH private key (gitignored)
  - Working copy for SSH connections
  - Auto-created from `id_ed25519.vault`
  - Never committed to git

## Setup for New Team Members

1. Get the `.vault_pass` file from a team member (securely!)
2. Place it in the repo root
3. Decrypt the SSH key:
   ```bash
   ansible-vault view secrets/id_ed25519.vault > secrets/id_ed25519
   chmod 600 secrets/id_ed25519
   ```
4. Run playbooks normally - variables auto-decrypt

## Adding/Updating Secrets

### Update variables (API tokens, etc.):
```bash
# Encrypt a new variable
echo 'my-secret-value' | ansible-vault encrypt_string --stdin-name 'my_var'

# Add the output to vault_vars.yml
```

### Update SSH key:
```bash
# Encrypt the key file
ansible-vault encrypt secrets/id_ed25519 --output=secrets/id_ed25519.vault

# Commit the .vault file
git add secrets/id_ed25519.vault
```

## Security

- ✅ **Committed to git**: `*.vault`, `*.vault.yml`, `*.pub`
- ❌ **Never commit**: `.vault_pass`, decrypted `id_ed25519`
