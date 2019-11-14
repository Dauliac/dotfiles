# import config.

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: all
export SHELL := /bin/bash


help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
BIN := ~/.local/bin/chezmoi
DIR := /tmp/dotfiles

add-chezmoi: ## Download and install chezmoi
	@echo "+ $@"
	@curl -sfL https://git.io/chezmoi | sh
	@mkdir -p ~/.local/bin
	@mv bin/chezmoi ${BIN}
	@rm -rf bin

add-vim:
	@echo "+ $@"
	@curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	@vim +PlugInstall +VundleInstall! +qall

add-fasd:
	@echo "+ $@"
	@[ ! -d ${DIR}/fasd ] && (git clone https://github.com/clvv/fasd.git ${DIR}/fasd)
	@cd ${DIR}/fasd && sudo make install

add-bat:
	@echo "+ $@"
	@curl -o ${DIR}/bat.tar.gz https://github.com/sharkdp/bat/releases/download/v0.12.1/bat-v0.12.1-x86_64-unknown-linux-gnu.tar.gz -OL
	@tar -xf ${DIR}/bat.tar.gz -C ${DIR}
	@mv ${DIR}/bat-v0.12.1-x86_64-unknown-linux-gnu/bat ~/.local/bin/bat

install: ## Install nerdfont, chezmoi repo, and some binaries
	@echo "+ $@"
	@mkdir -p ~/.local/share/fonts ${DIR}
	cd /tmp/dotfiles \
	&& curl -o Monoid.zip -L https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Monoid.zip \
		&& unzip Monoid.zip -d monoid \
		&& mv monoid/* ~/.local/share/fonts \
	&& curl -o gramalecte.zip -L -O https://grammalecte.net/grammalecte/zip/Grammalecte-fr-v1.3.0.zip \
		&& unzip gramalecte.zip -d grammalecte \
		&& mv grammalecte ~/.local/share/grammalecte

update: add-vim ## Chezmoi apply
	@echo "+ $@"
	@${BIN} apply


