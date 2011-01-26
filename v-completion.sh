# tab completion for v in bash and zsh
# source this file from your .bashrc or .zshrc
if complete &> /dev/null; then
  # bash tab completion
  complete -C 'v --complete "$COMP_LINE"' v
elif compctl &> /dev/null; then
  # zsh tab completion
  _v_zsh_tab_completion() {
    local compl
    read -l compl
    reply=(`v --complete "$compl"`)
  }
  compctl -U -K _v_zsh_tab_completion v
fi

