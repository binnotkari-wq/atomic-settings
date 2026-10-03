# justfile - system-settings
#
# Chaque recette appelle un script existant sans dupliquer sa logique.

set shell := ["bash", "-euo", "pipefail", "-c"]

# --- utilitaires ---

# Affiche la liste des recettes disponibles
_default:
    @just --list --list-heading $'Application des reglages systeme\n'

# Menu interactif groupé par catégories
_menu:
    #!/usr/bin/env bash
    
    # 1. Extraction et formatage des catégories et recettes
    # Lit le justfile, détecte les en-têtes '# ---' et les noms de recettes
    SELECTION=$(awk '
        /^# ---/ { 
            gsub(/^# --- *| *---$/, ""); 
            category=$0; 
            print "\n\033[1;35m══ " category " ══\033[0m" 
        }
        /^[a-zA-Z0-9_-]+:/ && !/^_/ { 
            split($1, a, ":"); 
            print "  " a[1] 
        }
    ' {{justfile()}} | fzf \
        --ansi \
        --layout=reverse \
        --border=rounded \
        --prompt="❯ " \
        --header="Choisis une recette par catégorie" \
        --preview '
            # Nettoie les espaces pour récuperer le nom exact de la recette
            recipe=$(echo {} | xargs);
            if [ -n "$recipe" ] && ! echo "{}" | grep -q "══"; then
                just --show "$recipe" 2>/dev/null || echo "Aperçu indisponible"
            fi
        ' \
        --preview-window=right:50%:wrap)

    # 2. Nettoyage du nom sélectionné (enlève les espaces)
    RECIPE=$(echo "$SELECTION" | xargs)

    # 3. Exécution si ce n'est pas une ligne d'en-tête de catégorie
    if [ -n "$RECIPE" ] && ! echo "$SELECTION" | grep -q "══"; then
        just "$RECIPE"
    fi

# Confirmations d'éxecution d'une recette.
_confirm recipe:
    #!/usr/bin/env bash
    read -p "Exécuter '{{recipe}}' ? [y/N] " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        just {{recipe}}
    fi

# --- Toute distribution Atomic ---

# Applique un karg pour la compression btrfs.
[group('Toute distribution Atomic')]
btrfs-kargs:
    ./scripts/btrfs-kargs.sh

# Applique les préférences desktop Gnome.
[group('Toute distribution Atomic')]
desktop_preferences:
    ./scripts/desktop_preferences.sh

# Desactivation des services et démarrages automatiques.
[group('Toute distribution Atomic')]
disable_startups:
    ./scripts/disable_startups.sh

# Compresse en zstd les données déployées en post-install par Bazzite (la compression n'étant pas active à ce stade)
[group('Toute distribution Atomic')]
existing-files_compress:
    ./scripts/existing-files_compress.sh

# Mise à jour des firmwares.
[group('Toute distribution Atomic')]
firmwares-update:
    ./scripts/firmwares-update.sh

# Mise en place des repos Github personnels (demande des credentials pour le repo privé).
[group('Toute distribution Atomic')]
github_setup:
    ./scripts/github_setup.sh

# Chargement du module NTSYNC au démarrage.
[group('Toute distribution Atomic')]
load_ntsync:
    ./scripts/load_ntsync.sh

# Limitation de l'espace disque alloué aux journaux système (100 Mo).
[group('Toute distribution Atomic')]
log_limit:
    ./scripts/log_limit.sh

# Installe des logiciel par rpm ostree (logiciels demandant une integration systeme).
[group('Toute distribution Atomic')]
rpmostree-packages:
    ./scripts/rpmostree-packages.sh

# Application des alias shell.
[group('Toute distribution Atomic')]
shell_alias:
    ./scripts/shell_alias.sh

# Correctif Plymouth/amdgpu (GPU AMD Vega intégré, ex: Picasso/Vega 8).
[group('Toute distribution Atomic')]
vega_plymouth-fix:
    ./scripts/vega_plymouth-fix.sh

# Paramétrage de la mémoire virtuelle.
[group('Toute distribution Atomic')]
vm-settings:
    ./scripts/vm-settings.sh

# Paramétrage de la ZRAM.
[group('Toute distribution Atomic')]
zram-settings:
    ./scripts/zram-settings.sh

# Applique l'ensemble des réglages communs à toute distribution type Fedora Atomic. Opérations idempotentes.
[group('workflows')]
all_atomic:
    just _confirm btrfs-kargs
    just _confirm desktop_preferences
    just _confirm disable_startups
    just _confirm existing-files_compress
    just _confirm firmwares-update
    just _confirm github_setup
    just _confirm load_ntsync
    just _confirm log_limit
    @echo "Une connection réseau est nécessaire pour cette étape (installation de paquets)."
    just _confirm rpmostree-packages
    just _confirm shell_alias
    @echo "Appliquer uniquement lorsque l'affichage graphique de saisie LUKS est KO :"
    just _confirm vega_plymouth-fix
    just _confirm vm-settings
    just _confirm zram-settings
    @echo "Réglages appliqués. Redémarrage dans 10 secondes (Ctrl+C pour annuler).."
    sleep 10
    sudo systemctl reboot