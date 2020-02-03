# import config.

UNAME := $(shell uname)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: all
export SHELL := /bin/bash

.DEFAULT_GOAL := help
BIN := ~/.local/bin/chezmoi
DIR := /tmp/dotfiles

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

add-chezmoi: ## Download and install chezmoi
	@echo "+ $@"
	@curl -sfL https://git.io/chezmoi | sh
	@mkdir -p ~/.local/bin
	@mv bin/chezmoi ${BIN}
	@rm -rf bin
	@~/.local/bin/chezmoi init


add-vim: ## Add vim plugins and confs
	@echo "+ $@"
	@curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	@vim +PlugInstall +VundleInstall! +qall

add-fasd: ## Install fasd
	@echo "+ $@"
	@[ ! -d ${DIR}/fasd ] && (git clone https://github.com/clvv/fasd.git ${DIR}/fasd)
	@cd ${DIR}/fasd && sudo make install

add-fd: ## Install fg
	@echo "+ $@"
	@curl -fLo /tmp/fd.deb \
    	https://github.com/sharkdp/fd/releases/download/v7.4.0/fd_7.4.0_amd64.deb \
	&& sudo dpkg -i /tmp/fd.deb \
	; rm -f /tmp/fd.deb-



add-bat: ## Install bat
	@echo "+ $@"
	@curl -o ${DIR}/bat.tar.gz https://github.com/sharkdp/bat/releases/download/v0.12.1/bat-v0.12.1-x86_64-unknown-linux-gnu.tar.gz -OL
	@tar -xf ${DIR}/bat.tar.gz -C ${DIR}
	@mv ${DIR}/bat-v0.12.1-x86_64-unknown-linux-gnu/bat ~/.local/bin/bat

add-grammalecte: ## Add grammalecte speller
	@echo "+ $@"
	@curl -LO -o gramalecte.zip \
		https://grammalecte.net/grammalecte/zip/Grammalecte-fr-v1.3.0.zip
	@unzip gramalecte.zip -d grammalecte
	@mv grammalecte ~/.local/share/grammalecte


install: ## Install nerdfont, chezmoi repo, and some binaries
	@echo "+ $@"
	@mkdir -p ~/.local/share/fonts ${DIR}
	cd /tmp/dotfiles \
	&& curl -o Monoid.zip -L https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Monoid.zip \
		&& unzip Monoid.zip -d monoid \
		&& mv monoid/* ~/.local/share/fonts
	@~/.local/bin/chezmoi apply

install-distrib: ## Install distribution packages, with yay,apt,..
	ifeq ($(UNAME), Linux)
	# do something Linux-y
	endif
	ifeq ($(UNAME), Solaris)
	# do something Solaris-y
	endif

