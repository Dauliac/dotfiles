# import config.

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help


help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

install: ## Install nerdfont, chezmoi repo, and some binaries
	./others/./install.sh
	cd /tmp \
	&& git clone https://github.com/ryanoasis/nerd-fonts.git \
	&& ./install \


update: install
	chezmoi apply
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	vim +PlugInstall +VundleInstall! +qall
	systemctl --user start purge-trash.timer purge-trash.service ssh-agent.service
	systemctl --user enable purge-trash.timer purge-trash.service ssh-agent.service

