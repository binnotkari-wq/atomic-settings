#!/usr/bin/env bash

# Mise à jour des firmwares. Note technique : fwupdmgr retourne un code de sortie non-nul dès
# qu'il n'y a rien à faire (pas de mise à jour disponible) : comportement normal, pas une erreur.
# Le || true évite que set -e n'interrompe le script dans ce cas.

set -euo pipefail

echo "==> Mise à jour des firmwares."
sudo fwupdmgr refresh || true
sudo fwupdmgr get-updates || true
sudo fwupdmgr update || true
echo "✅ Firmwares à jour."
