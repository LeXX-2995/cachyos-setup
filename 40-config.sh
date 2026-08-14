#!/usr/bin/env bash
set -euo pipefail

FISH_CONF_DIR="$HOME/.config/fish/conf.d"
FISH_CONF="$FISH_CONF_DIR/90-user-setup.fish"

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
SSH_AGENT_SERVICE="$SYSTEMD_USER_DIR/ssh-agent.service"

echo "========================================"
echo " User configuration setup"
echo "========================================"

#
# Fish configuration
#

echo
echo "==> Configuring Fish"

mkdir -p "$FISH_CONF_DIR"

cat > "$FISH_CONF" <<'EOF'
#
# User Fish configuration
#

#
# zoxide
#

if type -q zoxide
    zoxide init fish | source
end


#
# Useful aliases
#

if type -q eza
    alias ll='eza -lah'
    alias la='eza -a'
    alias l='eza -lah'
end

if type -q bat
    alias cat='bat'
end


#
# SSH agent
#

set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"

if status is-interactive
    set SSH_PRIVATE_KEY "$HOME/.ssh/lexx"
    set SSH_PUBLIC_KEY "$HOME/.ssh/lexx.pub"

    if test -f "$SSH_PRIVATE_KEY"
        #
        # If the public key doesn't exist yet, generate it.
        #
        if not test -f "$SSH_PUBLIC_KEY"
            ssh-keygen -y -f "$SSH_PRIVATE_KEY" > "$SSH_PUBLIC_KEY"
            chmod 644 "$SSH_PUBLIC_KEY"
        end

        #
        # Check whether this exact key is already loaded.
        #
        if test -S "$SSH_AUTH_SOCK"
            set PUBLIC_KEY_CONTENT (cat "$SSH_PUBLIC_KEY")

            if not ssh-add -L 2>/dev/null | string match -q "*$PUBLIC_KEY_CONTENT*"
                ssh-add "$SSH_PRIVATE_KEY"
            end
        end
    end
end
EOF

echo "==> Fish configuration created:"
echo "    $FISH_CONF"

#
# SSH agent
#

echo
echo "==> Configuring SSH agent"

mkdir -p "$SYSTEMD_USER_DIR"

cat > "$SSH_AGENT_SERVICE" <<'EOF'
[Unit]
Description=SSH authentication agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a %t/ssh-agent.socket

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.service

echo "==> SSH agent enabled"

#
# Plasma keyboard layout shortcut
#

echo
echo "==> Configuring Alt+Shift keyboard layout switching"

if command -v kwriteconfig6 &>/dev/null; then
    kwriteconfig6 \
        --file kxkbrc \
        --group Layout \
        --key Options \
        "grp:alt_shift_toggle"

    echo "==> Alt+Shift configured"
    echo "    Logout/login may be required."
else
    echo "WARNING: kwriteconfig6 not found"
    echo "         Keyboard shortcut was not changed."
fi

#
# Done
#

echo
echo "========================================"
echo " User configuration complete"
echo "========================================"

echo
echo "Fish config:"
echo "  $FISH_CONF"

echo
echo "SSH agent:"
echo "  systemctl --user status ssh-agent.service"

echo
echo "SSH agent socket:"
echo "  $XDG_RUNTIME_DIR/ssh-agent.socket"

echo
echo "SSH key expected at:"
echo "  $HOME/.ssh/lexx"

echo
echo "If this terminal was already open before running this script,"
echo "reload the Fish configuration with:"
echo
echo "  source $FISH_CONF"
echo
