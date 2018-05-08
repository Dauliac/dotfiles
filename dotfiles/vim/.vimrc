"==================== Vundle ==================
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" All of your Plugins must be added before the following line

" Change leader key
let mapleader = ','

"==================== My stuff =================
Plugin 'vim-airline/vim-airline'               "Bottom bar
Plugin 'tpope/vim-surround'                    "to add </>{}[]''
Plugin 'scrooloose/nerdcommenter'              "simply commenter
Plugin 'scrooloose/nerdtree'                   "simply commenter
Plugin 'tristen/vim-sparkup'                   "Html
Plugin 'morhetz/gruvbox'                       "Color
Plugin 'lilydjwg/colorizer'                    "Hilight color
Plugin 'Yggdroot/indentLine'                   "vertical indent symbol
Plugin 'vim-syntastic/syntastic'               "syntax checker
Plugin 'majutsushi/tagbar'                     "right bar with fuctions
Plugin 'pangloss/vim-javascript'               "javascript Syntax
Plugin 'tmux-plugins/vim-tmux-focus-events'    "Tmux integration
Plugin 'jelera/vim-javascript-syntax'          "javascript syntax

call vundle#end()
filetype plugin indent on
"==================== vim-powerline=============
"alway see status line
set laststatus=2
"see unicode
set encoding=utf-8

"====================Style====================
set number
"color-----
syntax on
let g:gruvbox_contrast_dark='hard'
colorscheme gruvbox
set termguicolors
set background=dark
let g:gruvbox_italic=1
let g:gruvbox_termcolors=16
hi Normal guibg=NONE ctermbg=NONE "Transparent background

"indent----
let g:indentLine_setColors = 0
let g:indentLine_char = '┆'
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set autoindent
set backspace=indent,eol,start

"tools----
set cursorline                               "See cursor line
set mouse=a                                  "Use the mouse like you expect
set ttymouse=xterm2                          "Use the mouse like you expect with tmux
set clipboard^=unnamedplus                   "Use X clipboard
set omnifunc=syntaxComplete#Complete         "Syntax completion
autocmd BufReadPost *                        "Keep the cursor position afer close
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   execute "normal! g`\"" |
    \ endif
set autoread
"listchars----
set list listchars=tab:▶-,trail:·,precedes:←,extends:→,eol:¬,nbsp:␣
"====================NERDTree====================
autocmd StdinReadPre * let s:std_in=1
autocmd vimenter * NERDTree
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

map <C-n> :NERDTreeToggle<CR>

"====================Airline====================
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='gruvbox'

"=====================Shortcuts===================
nmap <C-left> :bp<CR>
nmap <C-right> :bn<CR>
"nmap <C-S-o> :TagbarToggle<CR>
" Copy to the clipboard -- need +xterm-clipboard
 nmap <Leader>y "+y<CR>
" Permet de couper du code avec d sans écraser le contenu du registre
nmap <Leader>d "_d<CR>

"=====================NERDCommenter===================
filetype plugin on
let g:NERDSpaceDelims = 1
let g:NERDCompactSexyComs = 1
let g:NERDDefaultAlign = 'left'
let g:NERDCommentEmptyLines = 1
let g:NERDTrimTrailingWhitespace = 1

"=====================Vim-Javascript===================
let g:javascript_plugin_jsdoc = 1
set conceallevel=1

"=====================Syntastic===================
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

