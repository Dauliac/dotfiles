" Format on save: https://github.com/sbdchd/neoformat#basic-usage
augroup fmt
  autocmd!
  autocmd BufWritePre * undojoin | Neoformat
augroup END

" See message when error
let g:neoformat_only_msg_on_error = 1
" let g:neoformat_verbose = 1 " only affects the verbosity of Neoformat

" Disable cmake format
let g:neoformat_enabled_cmake = []
