#!/usr/bin/bash
# Run me to backup dotfiles
CONFIG=$HOME/.config
PWD=$(pwd)
BCKP=$PWD/dotfiles
rsync -avR $BCKP/.zshrc \
    $BCKP/.vimrc \
    $BCKP/.tmux.conf \
    $BCKP/vim/.NERDTreeBookmarks \
    $BCKP/.zsh_functions \
    $BCKP/.zprofile \
    $BCKP/.Xresources $HOME
rsync -avR $BCKP/bin/prez \
    $BCKP/bin/trash $HOME/bin/
rsync $BCKP/rofi \
    $BCKP/termite \
    $BCKP/polybar \
    $BCKP/i3 \
    $BCKP/dunst \
    $BCKP/compton $CONFIG
