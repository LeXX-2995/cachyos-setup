#!/usr/bin/env bash
set -euo pipefail

SOURCE_KEY="$HOME/lexx"

SSH_DIR="$HOME/.ssh"
TARGET_KEY="$SSH_DIR/lexx"
PUBLIC_KEY="${TARGET_KEY}.pub"

SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"

echo "========================================"
echo " SSH key setup"
echo "========================================"

#
# SSH directory
#

echo
echo "==> Preparing SSH directory"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

#
# Private key
#

if [[ -f "$SOURCE_KEY" && -f "$TARGET_KEY" ]]; then
    echo
    echo "ERROR: Both source and destination keys exist."
    echo
    echo "Source:"
    echo "  $SOURCE_KEY"
    echo
    echo "Destination:"
    echo "  $TARGET_KEY"
    echo
    echo "Nothing was changed."
    exit 1

elif [[ -f "$SOURCE_KEY" ]]; then
    echo
    echo "==> Moving SSH private key"

    mv "$SOURCE_KEY" "$TARGET_KEY"
    chmod 600 "$TARGET_KEY"

    echo "==> Private key installed:"
    echo "    $TARGET_KEY"

elif [[ -f "$TARGET_KEY" ]]; then
    echo
    echo "==> SSH private key is already installed"

    chmod 600 "$TARGET_KEY"

else
    echo
    echo "ERROR: SSH private key was not found."
    echo
    echo "Expected source file:"
    echo "  $SOURCE_KEY"
    echo
    echo "Copy the 'lexx' key to your home directory"
    echo "and run this script again."
    exit 1
fi

#
# Public key
#

echo
echo "==> Generating public key"

ssh-keygen \
    -y \
    -f "$TARGET_KEY" \
    > "$PUBLIC_KEY"

chmod 644 "$PUBLIC_KEY"

echo "==> Public key created:"
echo "    $PUBLIC_KEY"

#
# SSH agent
#

echo
echo "==> Starting SSH agent"

systemctl --user start ssh-agent.service

export SSH_AUTH_SOCK

if [[ ! -S "$SSH_AUTH_SOCK" ]]; then
    echo
    echo "ERROR: SSH agent socket was not found:"
    echo "  $SSH_AUTH_SOCK"
    echo
    echo "Run 40-config.sh first."
    exit 1
fi

echo "==> SSH agent socket:"
echo "    $SSH_AUTH_SOCK"

#
# Add key to agent
#

echo
echo "==> Adding key to SSH agent"

# Remove the same key from the agent first if it is already loaded.
# Failure here is harmless.
ssh-add -d "$TARGET_KEY" >/dev/null 2>&1 || true

ssh-add "$TARGET_KEY"

#
# Verify
#

echo
echo "==> Keys currently loaded in SSH agent:"
ssh-add -l

echo
echo "========================================"
echo " SSH key setup complete"
echo "========================================"

echo
echo "Private key:"
echo "  $TARGET_KEY"

echo
echo "Public key:"
echo "  $PUBLIC_KEY"

echo
echo "SSH agent socket:"
echo "  $SSH_AUTH_SOCK"
