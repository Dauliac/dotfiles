set path+=**

" Nice menu when typing `:find *.py`
set wildmode=longest,list,full
set wildmenu
" Ignore files
set wildignore+=*.pyc
set wildignore+=*_build/*
set wildignore+=**/coverage/*
set wildignore+=**/node_modules/*
set wildignore+=**/android/*
set wildignore+=**/ios/*
set wildignore+=**/.git/*

"==================== VIM Plug ==================
if ! filereadable(expand('~/.config/nvim/autoload/plug.vim'))
    echo "Downloading junegunn/nvim-plug to manage plugins..."
    silent !mkdir -p ~/.config/nvim/autoload/
    silent !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > ~/.config/nvim/autoload/plug.vim
    autocmd VimEnter * PlugInstall
endif

call plug#begin('~/.config/nvim/plugged')
Plug 'vim-airline/vim-airline'  "Bottom bar
Plug 'majutsushi/tagbar'        "right bar with fuctions
Plug 'Yggdroot/indentLine'      "vertical indent symbol
Plug 'lilydjwg/colorizer'       "Hilight color
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' } " Fzf
Plug 'junegunn/fzf.vim'                      "Fzf integration and completion
Plug 'tonychg/MagicTemplate'                 "Templates
Plug 'airblade/vim-gitgutter'                "Git display
Plug 'scrooloose/nerdcommenter' "simply commenter
" Plug 'google/vim-jsonnet', {'for': 'jsonnet'}   "jsonnet
" Plug 'rstacruz/sparkup', {'rtp': 'vim/', 'for': 'html'}   "Html
Plug 'christoomey/vim-tmux-navigator'        "Tmux integration in vim
" Plug 'dense-analysis/ale'                     " Liner
Plug 'dpelle/vim-Grammalecte', {'for': ['latex', 'markdown', 'txt']}

Plug 'mzlogin/vim-markdown-toc'
Plug 'tpope/vim-surround'
Plug 'aliou/bats.vim'

" Moderns that rule them all
Plug 'gruvbox-community/gruvbox' " Color scheme
Plug 'sbdchd/neoformat' " formatter
Plug 'neoclide/coc.nvim' , { 'branch' : 'release' } " Errors
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " Better hilight
Plug 'kkoomen/vim-doge', { 'do': { -> doge#install() } } " Documentation
Plug 'puremourning/vimspector' " Debugger

let g:ycm_key_list_select_completion = ['<TAB>', '<Down>']

call plug#end()

" Auto reload file
au FocusGained,BufEnter * :checktime

" automatically deletes all tralling whitespace on save.
autocmd BufWritePre * %s/\s\+$//e

let $BASH_ENV = "~/.bash_aliases"

" color
" syntax on

" filetype plugin on
" filetype plugin indent on

" change leader
let mapleader = ','

" xut code witout buffer
nmap <Leader>d "_d<CR>

" save sudo
command! W w !sudo tee %
