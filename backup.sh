#!/usr/bin/bash
# Run me to backup dotfiles
CONFIG=$HOME/.config
PWD=$(pwd)
BCKP=./dotfiles

mkdir -p dotfiles dotfiles/bin -p dotfiles/vim

cp -R $HOME/.zshrc \
    $HOME/.zprofile \
    $HOME/.zsh_functions \
    $HOME/.zsh_aliases \
    $HOME/.tmux.conf \
    $HOME/.vimrc \
    $HOME/.Xresources $BCKP
cp -R $HOME/bin/prez \
    $HOME/bin/trash $BCKP/bin
cp -r $HOME/.NERDTreeBookmarks $BCKP/vim/
cp -r $CONFIG/rofi/ $BCKP/rofi
cp -r $CONFIG/termite/ $BCKP/termite
cp -r $CONFIG/polybar/ $BCKP/polybar
cp -r $CONFIG/i3/ $BCKP/i3
cp -r $CONFIG/dunst/ $BCKP/dunst
cp -r $CONFIG/compton/ $BCKP/compton
