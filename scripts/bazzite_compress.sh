#!/usr/bin/env bash

# Lors du premier démarrage Bazzite déploie des données (flatpaks, homebrew, steam)
# A ce stade la compression BTRFS n'a ps encore été activée.
# On compresse ces données manuellement (opération unique).

set -euo pipefail

echo "==> Compression des données préinstallées par Bazzite"

# Le seul dossier de /var qui contient des données (
# NB : il sera vide si les flatpaks préinstallés par bazzite sont supprimés
sudo btrfs filesystem defragment -r -v -f -czstd /var/lib/flatpak

# Dossier utilisateur et linuxbrew existant
sudo btrfs filesystem defragment -r -v -f -czstd /var/home

