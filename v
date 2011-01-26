#!/bin/bash

# maintains a jump-list of the files you actually edit
#
# INSTALL:
#   * symlink this script into your PATH
#   * if you want tab completion, source v-completion.sh
#   * use v to edit files for a while to build up the db
#
# USE:
#   * v foo     # edits the most frecent file matching foo
#   * v foo bar # edits the most frecent file matching foo and bar
#   * v -r foo  # edits the highest ranked file matching foo
#   * v -t foo  # edits the most recently accessed file matching foo
#   * v -l foo  # list all files matching foo (by frecency)

# TODO:
#   * refactor the vim --cmd options into $vimopts, but shell escaping is
#     annoying

datafile="$HOME/.v"

# add entries
if [ "$1" = "--add" ]; then
 shift

 # maintain the file
 awk -v path="$*" -v now="$(date +%s)" -F"|" '
  BEGIN {
   rank[path] = 1
   time[path] = now
  }
  $2 >= 1 {
   if( $1 == path ) {
    rank[$1] = $2 + 1
    time[$1] = now
   } else {
    rank[$1] = $2
    time[$1] = $3
   }
   count += $2
  }
  END {
   if( count > 1000 ) {
    for( i in rank ) print i "|" 0.9*rank[i] "|" time[i] # aging
   } else for( i in rank ) print i "|" rank[i] "|" time[i]
  }
 ' "$datafile" 2>/dev/null > "$datafile.tmp"
 mv -f "$datafile.tmp" "$datafile"

# tab completion
elif [ "$1" = "--complete" ]; then
 awk -v q="$2" -F"|" '
  BEGIN {
   if( q == tolower(q) ) nocase = 1
   split(substr(q,3),fnd," ")
  }
  {
   if( system("test -e \"" $1 "\"") ) next
   if( nocase ) {
    for( i in fnd ) tolower($1) !~ tolower(fnd[i]) && $1 = ""
    if( $1 ) print $1
   } else {
    for( i in fnd ) $1 !~ fnd[i] && $1 = ""
    if( $1 ) print $1
   }
  }
 ' "$datafile" 2>/dev/null

else
 # list/go
 while [ "$1" ]; do case "$1" in
  -h) echo "v [-h][-l][-r][-t] args" >&2; exit;;
  -l) list=1;;
  -r) typ="rank";;
  -t) typ="recent";;
  --) while [ "$1" ]; do shift; fnd="$fnd $1";done;;
   *) fnd="$fnd $1";;
 esac; last=$1; shift; done
 [ "$fnd" ] || list=1

 # if we hit enter on a completion just go there
 [ -e "$last" ] && vim --cmd 'au BufRead * execute "silent !v --add " . shellescape(expand("%:p"), 1)' "$last" && exit

 # no file yet
 [ -f "$datafile" ] || exit

 vim="$(awk -v t="$(date +%s)" -v list="$list" -v typ="$typ" -v q="$fnd" -v tmpfl="$datafile.tmp" -F"|" '
  function frecent(rank, time) {
   dx = t-time
   if( dx < 3600 ) return rank*4
   if( dx < 86400 ) return rank*2
   if( dx < 604800 ) return rank/2
   return rank/4
  }
  function output(files, toopen, override) {
   if( list ) {
    if( typ == "recent" ) {
     cmd = "sort -nr >&2"
    } else cmd = "sort -n >&2"
    for( i in files ) if( files[i] ) printf "%-10s %s\n", files[i], i | cmd
    if( override ) printf "%-10s %s\n", "common:", override > "/dev/stderr"
   } else {
    if( override ) toopen = override
    print toopen
   }
  }
  function common(matches, fnd, nc) {
   for( i in matches ) {
    if( matches[i] && (!short || length(i) < length(short)) ) short = i
   }
   if( short == "/" ) return
   for( i in matches ) if( matches[i] && i !~ short ) x = 1
   if( x ) return
   if( nc ) {
    for( i in fnd ) if( tolower(short) !~ tolower(fnd[i]) ) x = 1
   } else for( i in fnd ) if( short !~ fnd[i] ) x = 1
   if( !x ) return short
  }
  BEGIN { split(q, a, " ") }
  {
   if( system("test -e \"" $1 "\"") ) next
   print $0 >> tmpfl
   if( typ == "rank" ) {
    f = $2
   } else if( typ == "recent" ) {
    f = t-$3
   } else f = frecent($2, $3)
   wcase[$1] = nocase[$1] = f
   for( i in a ) {
    if( $1 !~ a[i] ) delete wcase[$1]
    if( tolower($1) !~ tolower(a[i]) ) delete nocase[$1]
   }
   if( wcase[$1] > oldf ) {
    cx = $1
    oldf = wcase[$1]
   } else if( nocase[$1] > noldf ) {
    ncx = $1
    noldf = nocase[$1]
   }
  }
  END {
   if( cx ) {
    output(wcase, cx, common(wcase, a, 0))
   } else if( ncx ) output(nocase, ncx, common(nocase, a, 1))
  }
 ' "$datafile")"
 if [ $? -gt 0 ]; then
  rm -f "$datafile.tmp"
 else
  mv -f "$datafile.tmp" "$datafile"
  [ "$vim" ] && vim --cmd 'au BufRead * execute "silent !v --add " . shellescape(expand("%:p"), 1)' "$vim"
 fi
fi
