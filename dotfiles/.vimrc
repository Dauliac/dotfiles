"==================== Vundle ==================
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'


" Change leader key
let mapleader = ','

"==================== My stuff =================
Plugin 'vim-airline/vim-airline'               "Bottom bar
Plugin 'scrooloose/nerdcommenter'              "simply commenter
Plugin 'scrooloose/nerdtree'                   "simply commenter
Plugin 'tristen/vim-sparkup'                   "Html
Plugin 'morhetz/gruvbox'                       "Color
Plugin 'lilydjwg/colorizer'                    "Hilight color
Plugin 'Yggdroot/indentLine'                   "vertical indent symbol
Plugin 'majutsushi/tagbar'                     "right bar with fuctions
Plugin 'christoomey/vim-tmux-navigator'        "Tmux integration in vim
Plugin 'junegunn/fzf'                          "Fzf integration and completion
Plugin 'junegunn/fzf.vim'                      "Fzf integration and completion

call vundle#end()
filetype plugin indent on
"==================== vim-powerline=============
"alway see status line
set laststatus=2
"see unicode
set encoding=utf-8
"==================== TimeOut=============
set timeout           " for mappings
set timeoutlen=1000   " default value
set ttimeout          " for key codes
set ttimeoutlen=10    " unnoticeable small value
"====================Style====================
set number
set relativenumber

"color-----
syntax on
colorscheme gruvbox
let g:gruvbox_contrast_dark='medium'
let g:gruvbox_contrast_light='soft'
set background=dark
let g:gruvbox_italic=1
let g:gruvbox_termcolors=256
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

"Search----
set ignorecase
set smartcase

"tools----
set cursorline                               "See cursor line
set clipboard^=unnamedplus                   "Use X clipboard
set omnifunc=syntaxComplete#Complete         "Syntax completion
autocmd BufReadPost *                        "Keep the cursor position afer close
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   execute "normal! g`\"" |
    \ endif
set autoread

" Smart search----
set ignorecase
set smartcase
filetype plugin on
filetype plugin indent on

"listchars----
set list listchars=tab:▶-,trail:·,precedes:←,extends:→,eol:¬,nbsp:␣

"====================NERDTree====================
autocmd StdinReadPre * let s:std_in=1
autocmd vimenter * NERDTree
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
map <C-n> :NERDTreeToggle<CR>
let NERDTreeMinimalUI = 1

"====================Airline====================
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme='gruvbox'

"=====================Shortcuts===================
nmap <C-SHiftTab> :bp<CR>
nmap <C-r> :bn<CR>
"nmap <C-S-o> :TagbarToggle<CR>
"Copy to the clipboard -- need +xterm-clipboard
 nmap <Leader>y "+y<CR>
"Permet de couper du code avec d sans écraser le contenu du registre
nmap <Leader>d "_d<CR>

"Saving
nnoremap <C-s> :w<CR>
vnoremap <C-s> <Esc>:w<CR><C-s>gv
inoremap <C-s> <Esc>:w<CR><i>
"Exit
nnoremap <C-q> :qa<CR>
"Close buffer
nnoremap <C-x> :q<CR>

" Move
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" Splits open at the bottom and right, which is non-retarded, unlike vim defaults.
set splitbelow
set splitright

" Replace all is aliased to S.
noremap S :%s//g<Left><Left>

" Automatically deletes all tralling whitespace on save.
autocmd BufWritePre * %s/\s\+$//e

cnoremap w!! execute 'silent! write !sudo tee % >/dev/null' <bar> edit!
"=====================FZF===================
nnoremap <C-f> :Files<CR>
nnoremap <C-g> :GFiles<CR>
nnoremap <C-b> :Buffers<CR>

nmap q: :echo<CR>
imap q: :echo<CR>
nmap <F1> :echo<CR>
imap <F1> <C-o>:echo<CR>

let g:lightline = {
      \ 'colorscheme': 'challenger_deep',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'fugitive#head'
      \ },
      \ }

let g:seiya_auto_enable=1

let vim_markdown_preview_github=1
" Plugins Keys
let g:user_emmet_leader_key='<C-d>'
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

"=====================Tmux===================
let g:tmux_navigator_save_on_switch = 2