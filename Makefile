all: update

install:
	./others/./install.sh

update:
	chezmoi apply
	test -e ~/.vim/bundle/Vundle.vim || \
		( mkdir -p ~/.vim/bundle; \
		git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim)
	vim +VundleClean! +VundleInstall +VundleInstall! +qall

