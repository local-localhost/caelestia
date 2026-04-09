#!/usr/bin/env fish

function _out -a colour text
    set_color $colour
    echo ":: $text"
    set_color normal
end

function log -a text
    _out cyan $text
end

function warn -a text
    _out yellow $text
end

function die -a text
    _out red $text
    exit 1
end

command -sq git || die 'git is required to bootstrap the official installer.'
command -sq bash || die 'bash is required to run the official installer.'

set -q REPO_OWNER && set -l repo_owner $REPO_OWNER || set -l repo_owner local-localhost
set -q XDG_DATA_HOME && set -l data_home $XDG_DATA_HOME || set -l data_home $HOME/.local/share
set -q CAELESTIA_INSTALLER_DIR && set -l installer_dir $CAELESTIA_INSTALLER_DIR || set -l installer_dir $data_home/caelestia-installer
set -q INSTALLER_REPO_URL && set -l installer_repo_url $INSTALLER_REPO_URL || set -l installer_repo_url https://github.com/$repo_owner/caelestia-installer.git

set -l forwarded_args
set -l idx 1
while test $idx -le (count $argv)
    set -l arg $argv[$idx]

    switch $arg
        case --noconfirm
            set forwarded_args $forwarded_args -y
        case '--vscode=*'
            set forwarded_args $forwarded_args --vscode (string replace -- '--vscode=' '' $arg)
        case --aur-helper
            warn 'The official installer manages the AUR helper automatically; --aur-helper is ignored.'
            set idx (math $idx + 1)
        case '--aur-helper=*'
            warn 'The official installer manages the AUR helper automatically; --aur-helper is ignored.'
        case '*'
            set forwarded_args $forwarded_args $arg
    end

    set idx (math $idx + 1)
end

log 'The in-repo install.fish entrypoint is deprecated.'
log "Delegating to the official installer in $installer_dir"

if test -d "$installer_dir/.git"
    if test -n "$(git -C "$installer_dir" status --porcelain 2>/dev/null)"
        warn "Installer checkout has local changes; using it as-is: $installer_dir"
    else
        set -l branch (git -C "$installer_dir" symbolic-ref --quiet --short HEAD 2>/dev/null)
        if test -n "$branch"
            log 'Updating official installer checkout...'
            git -C "$installer_dir" fetch --tags --prune origin
            git -C "$installer_dir" pull --ff-only --tags origin $branch || die 'Failed to update official installer checkout.'
        else
            warn "Installer checkout is detached; using it as-is: $installer_dir"
        end
    end
else if test -e "$installer_dir"
    die "Installer path exists but is not a git checkout: $installer_dir"
else
    mkdir -p (path dirname "$installer_dir")
    log "Cloning official installer from $installer_repo_url"
    git clone "$installer_repo_url" "$installer_dir" || die 'Failed to clone official installer.'
end

exec bash "$installer_dir/install.sh" $forwarded_args
