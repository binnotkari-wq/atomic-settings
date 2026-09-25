#!/usr/bin/env bash

#####################################################################################
# post installation : configuration OS.                                             #
#####################################################################################

set -oue pipefail

executer_logique () {
  arreter_maj_automatiques
  mettre_a_jour_firmwares
  parametrer_zram
  parametrer_memoire_virtuelle
}

# Arrête et désactive temporairement rpm-ostreed-automatic.timer (le timer systemd qui, sur
# Silverblue, vérifie et met en scène ("stage") les mises à jour peu après le boot — c'est lui,
# pas GNOME Software, qui pilote la mise à jour automatique en arrière-plan). Sur une
# installation fraîche, ce timer peut se déclencher pendant l'exécution du script et entrer
# en conflit avec les opérations rpm-ostree du script (kargs, install), ou pire, écrire des
# données AVANT que la compression BTRFS ne soit activée par injecter_KARGS_compression_btrfs.
# On annule aussi toute transaction déjà en cours pour repartir sur une base saine.
#
# La réactivation (reactiver_maj_automatiques) est déclenchée via un trap EXIT plutôt qu'un
# appel explicite en fin de script : ainsi, même si le script échoue ou est interrompu
# (Ctrl+C, erreur sous set -e) à n'importe quelle étape après cet arrêt, le timer est
# systématiquement remis en route — le système n'est jamais laissé avec les mises à jour
# automatiques désactivées suite à un échec du script.
#
# Note : rpm-ostreed-automatic.timer n'est pas la seule source de transactions automatiques.
# GNOME Software effectue sa propre vérification en arrière-plan depuis la session graphique
# (via D-Bus, indépendamment de ce timer systemd) et peut relancer une transaction "upgrade"
# à tout moment pendant le script. On coupe donc aussi son paramètre d'auto-vérification et on
# termine le process en cours, pour réduire le risque qu'une nouvelle transaction démarre
# entre cet arrêt initial et les étapes rpm-ostree plus tardives du script (kargs, install).
arreter_maj_automatiques () {
  echo "==> Arrêt des mises à jour automatiques rpm-ostree pour la durée du script"
  sudo rpm-ostree cancel 2>/dev/null || true
  sudo systemctl stop rpm-ostreed-automatic.timer rpm-ostreed-automatic.service 2>/dev/null || true
  sudo systemctl disable rpm-ostreed-automatic.timer 2>/dev/null || true
  gsettings set org.gnome.software download-updates false 2>/dev/null || true
  gsettings set org.gnome.software download-updates-notify false 2>/dev/null || true
  pkill -x gnome-software 2>/dev/null || true
  trap reactiver_maj_automatiques EXIT
  echo "✅ Mises à jour automatiques stoppées le temps du script."
  echo ""
  echo "#####################################################################################"
  echo ""
}

# Réactive rpm-ostreed-automatic.timer, pour revenir au comportement par défaut du système
# (vérification/mise en scène périodique des mises à jour). Appelée automatiquement par le
# trap EXIT posé dans arreter_maj_automatiques, quelle que soit l'issue du script.
reactiver_maj_automatiques () {
  echo "==> Réactivation des mises à jour automatiques rpm-ostree"
  sudo systemctl enable --now rpm-ostreed-automatic.timer 2>/dev/null || true
  echo "✅ Mises à jour automatiques réactivées."
  echo ""
  echo "#####################################################################################"
  echo ""
}

# Sauvegarde un fichier existant en fichier.ext.backup avant modification (schéma A/B, à l'image
# des rootfs A/B des distributions atomiques : une version courante, une version précédente
# garantie fonctionnelle). Le backup est écrasé à chaque exécution : il ne conserve donc que
# l'état d'AVANT le dernier run, pas un historique. Ne fait rien si le fichier n'existe pas
# encore (rien à sauvegarder).
# Usage : backup_fichier <chemin_fichier> [sudo]
#   - passer "sudo" en second argument si le fichier nécessite les droits root pour être lu/copié
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

mettre_a_jour_firmwares() {
  echo "==> Mise à jour des firmwares."
  # fwupdmgr retourne un code de sortie non-nul dès qu'il n'y a rien à faire
  # (pas de mise à jour disponible) : comportement normal, pas une erreur.
  # Le || true évite que set -e n'interrompe le script dans ce cas.
  sudo fwupdmgr refresh || true
  sudo fwupdmgr get-updates || true
  sudo fwupdmgr update || true
  echo "✅ Firmwares à jour."
  echo ""
  echo "#####################################################################################"
  echo ""
}
	
parametrer_zram () {
  echo "==> paramétrage de la ZRAM"
  sudo mkdir -p /etc/systemd/zram-generator.conf.d
  backup_fichier /etc/systemd/zram-generator.conf.d/zram-generator_custom.conf sudo
cat <<'EOF' | sudo tee /etc/systemd/zram-generator.conf.d/zram-generator_custom.conf
[zram0]
zram-size = ram * 1.5
compression-algorithm = zstd
swap-priority = 100
EOF
  echo "✅ ZRAM paramétré."
  echo ""
  echo "#####################################################################################"
  echo ""
}

parametrer_memoire_virtuelle () {
  echo "==> paramétrage de la mémoire virtuelle"
  backup_fichier /etc/sysctl.d/99-vm-zram-parameters.conf sudo
cat <<'EOF' | sudo tee /etc/sysctl.d/99-vm-zram-parameters.conf
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
vm.max_map_count=1048576
EOF
  sudo sysctl --system
  echo "✅ Mémoire virtuelle paramétrée."
  echo ""
  echo "#####################################################################################"
  echo ""
}


executer_logique "$@"
