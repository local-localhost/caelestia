#!/usr/bin/env fish

set -l _reload false

# Ensure config directory exists
if ! test -d $argv
    mkdir -p $argv
end

# Ensure hypr-vars exists
if ! test -f $argv/hypr-vars.conf
    touch -a $argv/hypr-vars.conf
    set -l _reload true
end

# Ensure hypr-user exists
if ! test -f $argv/hypr-user.conf
    touch -a $argv/hypr-user.conf
    set -l _reload true
end

# Ensure hypr-environment exists
if ! test -f $argv/hypr-environment.conf
    set -q XDG_CONFIG_HOME && set -l xdg_config $XDG_CONFIG_HOME || set -l xdg_config $HOME/.config
    printf 'source = %s/hypr/environments/default.conf\n' $xdg_config >$argv/hypr-environment.conf
    set -l _reload true
end

# Ensure nwg-displays generated files exist so Hyprland can source them safely
set -q XDG_CONFIG_HOME && set -l hypr_config $XDG_CONFIG_HOME/hypr || set -l hypr_config $HOME/.config/hypr

if ! test -d $hypr_config
    mkdir -p $hypr_config
end

if ! test -f $hypr_config/monitors.conf
    touch -a $hypr_config/monitors.conf
    set -l _reload true
end

if ! test -f $hypr_config/workspaces.conf
    touch -a $hypr_config/workspaces.conf
    set -l _reload true
end

# Reload as needed
if test "$_reload" = true
    hyprctl reload
end
