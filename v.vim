" Add all files edited with vim to v
"
" This adds an autocommand that executes "v --add '/full/path/to/file'" after
" reading every file
au BufRead * execute "silent !v --add " . shellescape(expand("%:p"), 1)

