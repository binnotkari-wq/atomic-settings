#!/usr/bin/env bash

set -euo pipefail

echo "==> Compression des données qui ont provisionnées par Bazzite"
echo "==> en post-install, avant réactivation de la compression BTRFS"

# Le seul dossier de /var qui contient des données (
# NB : il sera vide si les flatpaks préinstallés par bazzite sont supprimés
sudo btrfs filesystem defragment -r -v -f -czstd /var/lib/flatpak

# Dossier utilisateur et linuxbrew existant
sudo btrfs filesystem defragment -r -v -f -czstd /var/home

echo "✅ Compression des données existantes réalisée avec succès."