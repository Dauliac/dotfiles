# import config.

UNAME := $(shell uname)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: all
export SHELL := /bin/bash

.DEFAULT_GOAL := help
CHEZMOI := ~/.local/bin/chezmoi
DIR := $(shell mktemp -d)

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

add-chezmoi: ## Download and install chezmoi
	@echo "+ $@"
	@cd ${DIR}; curl -sfL https://git.io/chezmoi | sh
	@mv -f ${DIR}/bin/chezmoi ${CHEZMOI}
	@rm -rf ${DIR}/bin
	@${CHEZMOI} init

add-services: ## Add systemd --user services
	@echo "+ $@"
	systemctl enable --now systemd-networkd-wait-online.service
	systemctl --user daemon-reload
	systemctl --user --now status timers.target
	systemctl --user --now enable ssh-agent.service
	systemctl --user --now enable purge-trash.service
	systemctl --user --now enable purge-trash.timer
	systemctl --user --now enable backup.timer
	systemctl --user --now enable backup.service

add-vim: ## Add vim plugins and confs
	@echo "+ $@"
	@mkdir -p ~/.vim/autoload/
	@curl -fL -o ~/.vim/autoload/plug.vim --create-dirs \
    	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	@vim +PlugInstall +VundleInstall! +qall

add-fasd: ## Install fasd
	@echo "+ $@"
	@[ ! -d ${DIR}/fasd ] && (git clone https://github.com/clvv/fasd.git ${DIR}/fasd)
	@cd ${DIR}/fasd && sudo make install

add-fd: ## Install fg
	@echo "+ $@"
	@curl -fLo ${DIR}/fd.deb \
    	https://github.com/sharkdp/fd/releases/download/v7.4.0/fd_7.4.0_amd64.deb \
	&& sudo dpkg -i ${DIR}/fd.deb \
	; rm -f ${DIR}/fd.deb-

add-bat: ## Install bat
	@echo "+ $@"
	@curl -o ${DIR}/bat.tar.gz https://github.com/sharkdp/bat/releases/download/v0.12.1/bat-v0.12.1-x86_64-unknown-linux-gnu.tar.gz -L
	@tar -xf ${DIR}/bat.tar.gz -C ${DIR}
	@mv -f ${DIR}/bat-v0.12.1-x86_64-unknown-linux-gnu/bat ~/.local/bin/bat

add-grammalecte: ## Add grammalecte speller
	@echo "+ $@"
	curl -L  https://grammalecte.net/grammalecte/zip/Grammalecte-fr-v1.3.0.zip \
		--output ${DIR}/grammalecte.zip
	@unzip ${DIR}/grammalecte.zip -d ${DIR}/grammalecte
	@rm -fr ~/.local/share/grammalecte
	@mv -f ${DIR}/grammalecte ~/.local/share/grammalecte


install: add-grammalecte add-bat add-fd add-fasd add-bat add-vim add-chezmoi ## Install nerdfont, chezmoi repo, and some binaries
	@echo "+ $@"
	@mkdir -p ~/.local/share/fonts
	cd /tmp/dotfiles \
	&& curl -o ${DIR}/Monoid.zip -L https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Monoid.zip \
		&& unzip ${DIR}/Monoid.zip -d monoid \
		&& mv -f ${DIR}/monoid/* ~/.local/share/fonts
	@~/.local/bin/chezmoi apply

install-distrib: ## Install distribution packages, with yay,apt,..
	ifeq ($(UNAME), Linux)
	# do something Linux-y
	endif
	ifeq ($(UNAME), Solaris)
	# do something Solaris-y
	endif

