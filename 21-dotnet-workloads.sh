#!/usr/bin/env bash
set -euo pipefail

echo "==> Updating .NET workload manifests"
sudo dotnet workload update

echo
echo "==> Installing .NET workloads"

workloads=(
    wasm-tools
    wasm-tools-net8
    maui-android
)

for workload in "${workloads[@]}"; do
    echo
    echo "==> Installing workload: $workload"
    sudo dotnet workload install "$workload"
done

echo
echo "==> Installed .NET workloads:"
dotnet workload list

echo
echo "==> .NET workloads setup complete"
