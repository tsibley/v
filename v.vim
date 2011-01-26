" Always add files to v
"
" At the moment, sourcing this from your .vimrc will double add entries since
" v invokes vim with this using the --cmd option
"
" This adds an autocommand that executes "v --add '/full/path/to/file'" after
" reading every file
au BufRead * execute "silent !v --add " . shellescape(expand("%:p"), 1)
