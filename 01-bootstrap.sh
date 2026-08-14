#!/usr/bin/env bash
set -euo pipefail

echo "==> Updating system"
sudo pacman -Syu --noconfirm

echo
echo "==> Checking yay"

if command -v yay &>/dev/null; then
    echo "==> yay is already installed"
else
    echo "==> Installing yay"
    sudo pacman -S --needed --noconfirm yay
fi

echo
echo "==> Bootstrap complete"
