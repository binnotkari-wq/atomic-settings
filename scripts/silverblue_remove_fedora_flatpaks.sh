#!/usr/bin/env bash

# Suppression des Flatpak du repo Fedora

set -euo pipefail

echo "==> Nettoyage des flatpaks Fedora."
mapfile -t REFS_FEDORA < <(flatpak list --system --columns=ref | grep "fedoraproject")
if ((${#REFS_FEDORA[@]})); then
  sudo flatpak pin --remove "${REFS_FEDORA[@]}" 2>/dev/null || true
fi
mapfile -t APPS_FEDORA < <(flatpak list --columns=application,origin | grep -i 'fedora' | awk '{print $1}')
if ((${#APPS_FEDORA[@]})); then
  sudo flatpak uninstall -y "${APPS_FEDORA[@]}" 2>/dev/null || true
fi
sudo flatpak remote-delete --force fedora 2>/dev/null || true
sudo flatpak remote-delete --force fedora-testing 2>/dev/null || true
sudo flatpak uninstall --unused
echo "✅ Flatpaks Fedora supprimés avec succès."

