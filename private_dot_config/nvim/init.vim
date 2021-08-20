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
Plug 'morhetz/gruvbox'          "Color
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
Plugin 'frazrepo/vim-rainbow'

" Moderns that rule them all
Plug 'sbdchd/neoformat' " formatter
Plug 'neoclide/coc.nvim' , { 'branch' : 'release' } " Errors
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " Better hilight
Plug 'kkoomen/vim-doge', { 'do': { -> doge#install() } } " Documentation

let g:ycm_key_list_select_completion = ['<TAB>', '<Down>']

call plug#end()

"filetype plugin indent on

"====================Vanilla====================
set encoding=utf-8

set mouse=a

set backupcopy=auto

" Reload after terminal command
set autoread

" Auto reload file
au FocusGained,BufEnter * :checktime

" UNDO and swap files
set spellfile=$XDG_CONFIG_HOME/nvim/spell/en.utf-8.add
set backupdir=$XDG_CONFIG_HOME/nvim/tmp,.
set directory=$XDG_CONFIG_HOME/nvim/tmp,.

" automatically deletes all tralling whitespace on save.
autocmd BufWritePre * %s/\s\+$//e

" indentation
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType typescript setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType groovy setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType tf setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType ruby setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType html setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType tf   setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType css  setlocal noet ci pi sts=0 sw=4 ts=4
autocmd FileType java setlocal noet ci pi sts=0 sw=4 ts=4
autocmd FileType cc setlocal noet ci pi sts=0 sw=4 ts=4
autocmd FileType cpp setlocal noet ci pi sts=0 sw=4 ts=4
autocmd FileType c setlocal noet ci pi sts=0 sw=4 ts=4
autocmd FileType jsonnet setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType go setlocal noet ci pi sts=0 sw=4 ts=4
autocmd Filetype gitcommit setlocal spell textwidth=72

" see cursor line
set cursorline                               "See cursor line
set clipboard+=unnamedplus                   "Use X clipboard
set omnifunc=syntaxComplete#Complete         "Syntax completion

let $BASH_ENV = "~/.bash_aliases"

" Spell
set spell

" display positional numbers
set number
set relativenumber

" listchars
set list listchars=tab:▶-,trail:·,precedes:←,extends:→,eol:¬,nbsp:␣

" color
syntax on

" indent
let g:indentLine_setColors = 0
let g:indentLine_char = '┆'
set tabstop=4
set shiftwidth=4
set softtabstop=4
set laststatus=2
set expandtab
set smartindent
set backspace=indent,eol,start
set cindent
set cinoptions=(0,u0,U0

" smart search
set ignorecase
set smartcase
filetype plugin on
filetype plugin indent on

"=====================Shortcuts===================
" change leader
let mapleader = ','

" copy to the clipboard -- need +xterm-clipboard
 nmap <Leader>y "+y<CR>

" xut code witout buffer
nmap <Leader>d "_d<CR>

" save sudo
command! W w !sudo tee %

"==================== COC Completion ====================
" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("nvim-0.5.0") || has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif
" Run before: CocInstall coc-tsserver
let g:coc_global_extensions = [ 'coc-tsserver' ]

" To complete with C-y
" From:
"   https://github.com/neoclide/coc.nvim/wiki/Completion-with-sources
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" use <tab> for trigger completion and navigate to the next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ coc#refresh()

" From:
"   https://medium.com/swlh/ultimate-vim-typescript-setup-34b5ac5c8c4e
" Remap keys for applying codeAction to the current line.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
"
" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Vim Coc pairs
autocmd FileType markdown let b:coc_pairs_disabled = ['`']

"====================FZF====================
" This is the default extra key bindings
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" Default fzf layout
" - down / up / left / right
let g:fzf_layout = { 'down': '~40%' }

let g:fzf_tags_command = 'ctags -R'

" Enable per-command history.
" CTRL-N and CTRL-P will be automatically bound to next-history and
" previous-history instead of down and up. If you don't like the change,
" explicitly bind the keys to down and up in your $FZF_DEFAULT_OPTS.
let g:fzf_history_dir = '~/.local/share/fzf-history'

nnoremap <C-f> :Files<CR>
nnoremap <C-g> :GFiles<CR>
nnoremap <C-b> :Buffers<CR>
nnoremap <C-v> :Ag <CR>

" Insert mode completion
imap <c-x><c-k> <plug>(fzf-complete-word)
inoremap <expr> <c-x><c-k> fzf#vim#complete#word({'left': '13%'})
inoremap <expr> <c-x><c-k> fzf#vim#complete('cat /usr/share/dict/french')

imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-l> <plug>(fzf-complete-line)

" Hide statusline
" When fzf starts in a terminal buffer, you may want to hide the statusline of the containing buffer.
autocmd! FileType fzf
autocmd  FileType fzf set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler

" Augmenting Ag command using fzf#vim#with_preview function
"   * fzf#vim#with_preview([[options], [preview window], [toggle keys...]])
"     * For syntax-highlighting, Ruby and any of the following tools are required:
"       - Bat: https://github.com/sharkdp/bat
"       - Highlight: http://www.andre-simon.de/doku/highlight/en/highlight.php
"       - CodeRay: http://coderay.rubychan.de/
"       - Rouge: https://github.com/jneen/rouge
"
"   :Ag  - Start fzf with hidden preview window that can be enabled with "?" key
"   :Ag! - Start fzf in fullscreen and display the preview window above
command! -bang -nargs=* Ag
  \ call fzf#vim#ag(<q-args>,
  \                 <bang>0 ? fzf#vim#with_preview('up:60%')
  \                         : fzf#vim#with_preview('right:50%:hidden', '?'),
  \                 <bang>0)

" Likewise, Files command with preview window
command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)


"====================Airline====================
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme='gruvbox'

"====================Gruvbox====================
colorscheme gruvbox
" my color scheme is a plugin
let g:gruvbox_terminal_colors = 1
let g:gruvbox_contrast_dark='medium'
let g:gruvbox_contrast_light='soft'
set background=dark
let g:gruvbox_italic=1
let g:gruvbox_termcolors=256

" transparent background
hi Normal guibg=NONE ctermbg=NONE "Transparent background

"=====================NERDCommenter===================
filetype plugin on
let g:NERDSpaceDelims = 1
let g:NERDCompactSexyComs = 1
let g:NERDDefaultAlign = 'left'
let g:NERDCommentEmptyLines = 0
let g:NERDTrimTrailingWhitespace = 1

"=====================Latex===================
let g:vimtex_view_method = 'zathura'
let g:vimtex_compiler_method = 'latexrun'
let g:vimtex_view_enabled = 1

"=====================Tmux===================
let g:tmux_navigator_save_on_switch = 2

"=====================Templates===================
let g:templatesDirectory = $HOME."/Templates/"

"=====================GitGutter===================
" allow to change color
let g:gitgutter_override_sign_column_highlight = 0
" remove basic backgorund
highlight SignColumn ctermbg=none
" change 'add' symbol
highlight GitGutterAdd ctermbg=none
highlight GitGutterAdd ctermfg=Green
" change 'change' symbol
highlight GitGutterChange ctermbg=none
highlight GitGutterChange ctermfg=Cyan
" change 'delete' symbol
highlight GitGutterDelete ctermbg=none
highlight GitGutterDelete ctermfg=Red
" change 'change-delete' symbol
highlight GitGutterChangeDelete ctermbg=none
highlight GitGutterChangeDelete ctermfg=Yellow

"=====================Grammalecte===================
" grammalecte script from https://grammalecte.net/#download
let g:grammalecte_cli_py='~/.local/lib/grammalecte/grammalecte-cli.py'

"====================Gitmoji=====================
nmap <Leader>j "=system('gitmoji-selector')<C-M>P


"====================Dodge=====================
" Preserve existing doge settings.
let g:doge_doc_standard_typescript = 'tsdoc'

"====================Chezmoi=====================
autocmd BufWritePost ~/.local/share/chezmoi/* ! chezmoi apply --source-path %

"====================Treesitter=====================
lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = {
    "cpp",
    "bash",
    "php",
    "regex",
    "yaml",
    "toml",
    "typescript",
    "cmake",
    "dockerfile",
    "vim",
    "json"
  }, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  -- ignore_install = { "javascript" }, -- List of parsers to ignore installing
  highlight = {
    enable = true,              -- false will disable the whole extension
    -- disable = { "c", "rust" },  -- list of language that will be disabled
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}
EOF
