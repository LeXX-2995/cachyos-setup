#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing CLI tools"

packages=(
    bat
    eza
    fd
    fzf
    jq
    tree
    zoxide
    git-delta
)

sudo pacman -S --needed --noconfirm "${packages[@]}"

echo
echo "==> Installed CLI tools:"
for package in "${packages[@]}"; do
    if pacman -Q "$package" &>/dev/null; then
        printf "  ✓ %s\n" "$package"
    else
        printf "  ✗ %s\n" "$package"
    fi
done

echo
echo "CLI setup complete."
