#!/usr/bin/bash
sudo cp ./st/st /usr/local/bin
sudo cp ./host /etc/host
dotdrop --cfg=$DOTFILES -p $HOST install

systemctl --user enable ssh-agent
systemctl --user start ssh-agent
