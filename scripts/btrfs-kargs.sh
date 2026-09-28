#!/usr/bin/env bash

# Karg : compression btrfs zstd:1 (composefs ne prenant pas en compte l'intégralité
# de /etc/fstab - valade pour toutes les Fedora Atomic et autres dérivés bootc).
# https://gitlab.com/fedora/ostree/sig/-/work_items/72

set -euo pipefail

# Arrêt des mises à jour automatiques rpm-ostree pour la durée du script.
sudo rpm-ostree cancel 2>/dev/null || true
sudo systemctl stop rpm-ostreed-automatic.timer rpm-ostreed-automatic.service 2>/dev/null || true
sudo systemctl disable rpm-ostreed-automatic.timer 2>/dev/null || true
gsettings set org.gnome.software download-updates false 2>/dev/null || true
gsettings set org.gnome.software download-updates-notify false 2>/dev/null || true
pkill -x gnome-software 2>/dev/null || true
echo "Mises à jour automatiques stoppées le temps du script."

echo "Injection KARG : mise en place compression BTRFS."
sudo rpm-ostree cancel 2>/dev/null || true
sudo rpm-ostree kargs --delete="rootflags=subvol=root" --append="rootflags=subvol=root,compress=zstd:1"

# Réactivation des mises à jour automatiques rpm-ostree.
sudo systemctl enable --now rpm-ostreed-automatic.timer 2>/dev/null || true
echo "Mises à jour automatiques réactivées."

echo "La compression peut être vérifiée en comparant l'espace avant/après création d'un fichier de 1Go :"
echo "sudo compsize /var/home/benoit"
echo "dd if=/dev/zero of=myfs.img bs=1024 count=1024000"
echo "sudo compsize /var/home/benoit"
