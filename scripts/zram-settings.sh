#!/usr/bin/env bash

set -euo pipefail

echo "==> Paramétrage de la ZRAM"

if sudo grep -qF 'zram-size = ram * 1.5' /etc/systemd/zram-generator.conf.d/zram-generator_custom.conf 2>/dev/null; then
    echo "zram déjà configuré, rien à faire."
    exit 0
fi

backup_fichier () {
    local fichier="$1"
    local besoin_sudo="${2:-}"

    local backup="${fichier}.backup"

    if [[ "$besoin_sudo" == "sudo" ]]; then
        # Ne faire le backup que si le backup n'existe pas déjà
        if sudo test -f "$fichier" && ! sudo test -f "$backup"; then
            sudo cp -a "$fichier" "$backup"
            echo "  ↳ Backup créé : ${backup}"
        fi
    else
        if [[ -f "$fichier" ]] && [[ ! -f "$backup" ]]; then
            cp -a "$fichier" "$backup"
            echo "  ↳ Backup créé : ${backup}"
        fi
    fi
}

sudo mkdir -p /etc/systemd/zram-generator.conf.d
backup_fichier /etc/systemd/zram-generator.conf.d/zram-generator_custom.conf sudo
cat <<'EOF' | sudo tee /etc/systemd/zram-generator.conf.d/zram-generator_custom.conf
[zram0]
zram-size = ram * 1.5
compression-algorithm = zstd
swap-priority = 100
EOF

echo "✅ ZRAM paramétrée."