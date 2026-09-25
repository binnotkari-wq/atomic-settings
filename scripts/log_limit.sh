#!/usr/bin/env bash

# Limitation de la l'espace disque accordé aux journaux système

set -euo pipefail

backup_fichier () {
  local fichier="$1"
  local besoin_sudo="${2:-}"

  if [[ "$besoin_sudo" == "sudo" ]]; then
    if sudo test -f "$fichier"; then
      sudo cp -a "$fichier" "${fichier}.backup"
      echo "  ↳ Backup créé : ${fichier}.backup"
    fi
  else
    if [[ -f "$fichier" ]]; then
      cp -a "$fichier" "${fichier}.backup"
      echo "  ↳ Backup créé : ${fichier}.backup"
    fi
  fi
}

echo "==> Limite de l'espace disque occupé par les journaux."
sudo mkdir -p /etc/systemd/journald.conf.d/
backup_fichier /etc/systemd/journald.conf.d/00-limit-size.conf sudo
echo -e "[Journal]\nSystemMaxUse=100M" | sudo tee /etc/systemd/journald.conf.d/00-limit-size.conf
sudo systemctl restart systemd-journald
echo "✅ Journaux limités avec succés."
