#!/usr/bin/env bash

# On surcharge le fichier de configuration par défaut, en passant par le dossier *.conf.d
# Cela permet de personnaliser les paramètre de la config par défaur sans la modifier directement.
# Le backup d'un éventuel fichier existant est réalisé au préalable.

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

echo "==> paramétrage de la ZRAM"
sudo mkdir -p /etc/systemd/zram-generator.conf.d
backup_fichier /etc/systemd/zram-generator.conf.d/zram-generator_custom.conf sudo
cat <<'EOF' | sudo tee /etc/systemd/zram-generator.conf.d/zram-generator_custom.conf
[zram0]
zram-size = ram * 1.5
compression-algorithm = zstd
swap-priority = 100
EOF
