#!/usr/bin/env bash

set -euo pipefail

echo "==> Injection des fichiers de configuration desktop, et application des préférences."

# Sauvegarde un fichier existant en .backup avant modification.
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

# Télécharge un fichier depuis $src vers $dest, sauvegarde l'ancienne version si
# présente, applique les permissions demandées. Idempotent par nature : on peut
# relancer, le fichier est simplement re-synchronisé avec la source.
telecharger_fichier () {
    local dest="$1" src="$2" perms="$3" avec_sudo="${4:-non}"
    backup_fichier "$dest" "$avec_sudo"
    if [[ "$avec_sudo" == "oui" ]]; then
        sudo curl -fsSL "$src" -o "$dest"
        sudo chmod "$perms" "$dest"
    else
        curl -fsSL "$src" -o "$dest"
        chmod "$perms" "$dest"
    fi
}

sudo mkdir -p /var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/x86_64/stable/policies
sudo mkdir -p /etc/firefox/policies
sudo mkdir -p /etc/profile.d
sudo mkdir -p /etc/profile.d/local.d
sudo mkdir -p /etc/profile.d/profile
sudo mkdir -p /etc/dconf/db/local.d
sudo mkdir -p /etc/dconf/profile
mkdir -p "$HOME/Modèles"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
url="${SCRIPT_DIR}/../system_files"

telecharger_fichier "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/x86_64/stable/policies/policies.json" "$url/etc/firefox/policies/policies.json" 644 oui
telecharger_fichier "/etc/firefox/policies/policies.json"      "$url/etc/firefox/policies/policies.json"      644 oui
telecharger_fichier "/etc/profile.d/10-environment.sh"         "$url/etc/profile.d/10-environment.sh"         644 oui
telecharger_fichier "/etc/dconf/db/local.d/00-defaults"        "$url/etc/dconf/db/local.d/00-defaults"        644 oui
telecharger_fichier "/etc/dconf/profile/user"                  "$url/etc/dconf/profile/user"                  644 oui
telecharger_fichier "$HOME/Modèles/Fichier Markdown.md"        "$url/etc/skel/Modèles/Fichier%20Markdown.md"  644 non
telecharger_fichier "$HOME/Modèles/Fichier texte.txt"          "$url/etc/skel/Modèles/Fichier%20texte.txt"    644 non
telecharger_fichier "$HOME/Modèles/Script.sh"                  "$url/etc/skel/Modèles/Script.sh"              755 non

# activation des préférences dconf injectées
sudo dconf update

# Ajouter les extragroups
# - user : extraGroups = [ "libvirtd" "kvm" ];

echo "✅ Configuration desktop et préférences mises en place avec succès."