if [[ -o interactive ]]; then
  TRAPWINCH() {
    zle && { zle reset-prompt; zle -R }
  }
fi
