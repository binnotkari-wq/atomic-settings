#!/usr/bin/env bash

# Config mémoire virtuelle à appliquer à Silverblue. La config de Bazzite par défaut est déjà OK.
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

echo "==> paramétrage de la mémoire virtuelle"
 backup_fichier /etc/sysctl.d/99-vm-zram-parameters.conf sudo
cat <<'EOF' | sudo tee /etc/sysctl.d/99-vm-zram-parameters.conf
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
vm.max_map_count=1048576
EOF
