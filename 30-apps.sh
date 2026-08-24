#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing desktop applications"

if ! command -v yay &>/dev/null; then
    echo "ERROR: yay is not installed."
    echo "Run 01-bootstrap.sh first."
    exit 1
fi

pacman_packages=(
    telegram-desktop
    onlyoffice-bin
    vlc
    mailspring
)

aur_packages=(
    google-chrome
    zapzap-bin
    rustdesk-bin
    jamesdsp-pipewire-bin
    chatgpt-desktop-bin
    postman-bin
    tabby-bin
    yandex-music
    yandex-disk
    yandex-disk-indicator
)

echo
echo "==> Installing packages from official repositories"
sudo pacman -S --needed --noconfirm "${pacman_packages[@]}"

echo
echo "==> Installing AUR packages"
yay -S --needed --noconfirm "${aur_packages[@]}"

echo
echo "==> Desktop applications setup complete"
