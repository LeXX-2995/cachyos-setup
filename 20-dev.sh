#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing development tools"

pacman_packages=(
    dotnet-sdk
    dotnet-sdk-8.0
    nodejs
    npm
)

aur_packages=(
    visual-studio-code-bin
    jetbrains-toolbox
)

echo
echo "==> Installing packages from official repositories"
sudo pacman -S --needed --noconfirm "${pacman_packages[@]}"

echo
echo "==> Installing AUR packages"
yay -S --needed --noconfirm "${aur_packages[@]}"

echo
echo "==> Installed .NET SDKs:"
dotnet --list-sdks

echo
printf "Node.js: "
node --version

printf "npm:     "
npm --version

printf "Git:     "
git --version

printf "VS Code: "
code --version | head -n 1

echo
echo "==> Development setup complete"
echo "    Rider and DataGrip should be installed through JetBrains Toolbox."
