#!/bin/bash

set -euo pipefail

new_dotfile_symlink() {
    local source=${1}
    local target=${2}
    local abs_target
    local link_target

    # macOS doesn't have readlink -f
    abs_target=$(pwd)/"${target}"

    mkdir -p "$(dirname "${source}")"

    if [[ -L "${source}" ]]; then
        link_target=$(readlink "${source}")
        if [[ "${link_target}" != "${abs_target}" ]]; then
            echo >&2 "${source}: path exists and is symlinked to ${link_target}"
            return 1
        fi

        echo "${source}: path already correctly linked"
        return
    elif [[ -e "${source}" ]]; then
        echo >&2 "${source}: path exists and is not a symlink"
        return 1
    fi

    echo "Symlinking ${source} to ${abs_target}"
    ln -sn "${abs_target}" "${source}"
}

cd "$(dirname "${BASH_SOURCE[0]}")"

# git
new_dotfile_symlink ~/.gitconfig files/git/gitconfig
if [[ "$(uname -r)" = *Microsoft* ]]; then
    new_dotfile_symlink ~/.gitconfig.platform files/git/gitconfig.wsl
fi

# Mercurial
new_dotfile_symlink ~/.hgrc files/hgrc

# rg
new_dotfile_symlink ~/.ripgreprc files/ripgreprc

# emacs
new_dotfile_symlink ~/.emacs files/emacs

# vim
new_dotfile_symlink ~/.vim files/vim
new_dotfile_symlink ~/.vimrc files/vim/vimrc
# nvim
new_dotfile_symlink ~/.config/nvim files/vim

# vscode
if [[ "$(uname -s)" == Darwin ]]; then
    vscode_dir=~/Library/Application\ Support/Code/User
else
    vscode_dir=~/.config/Code/User
fi
new_dotfile_symlink "${vscode_dir}"/keybindings.json files/vscode/keybindings.json
new_dotfile_symlink "${vscode_dir}"/settings.json files/vscode/settings.json

# tmux
new_dotfile_symlink ~/.tmux files/tmux
new_dotfile_symlink ~/.tmux.conf files/tmux.conf

# X11
if [[ "$(uname -r)" != *Microsoft* ]]; then
    new_dotfile_symlink ~/.Xresources files/Xresources
fi

# makepkg
if [[ -f /etc/arch-release ]]; then
    new_dotfile_symlink ~/.makepkg.conf files/makepkg.conf
fi
