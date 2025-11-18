#!/bin/zsh
# Source anything .zsh-preload in .zshrc.d.
# because # https://github.com/mattmc3/zshrc.d
# will load the rest
# source ${ZDOTDIR:-$HOME}/.zshenv
# ZFUNCDIR=${ZDOTDIR:-$HOME}/.zfunctions
# fpath=($ZFUNCDIR $fpath)
# autoload -Uz $ZFUNCDIR/*(.:t)
# set -x;
export color_prompt=yes
# Set any zstyles you might use for configuration.
[[ ! -f ${ZDOTDIR:-$HOME}/.zstyles ]] || source ${ZDOTDIR:-$HOME}/.zstyles

[[ -d ${ZDOTDIR:-$HOME}/.antidote ]] || {
  echo "🔧 Installing Antidote..."
  git clone --depth=1 https://github.com/mattmc3/antidote "${ZDOTDIR:-$HOME}/.antidote"
}
if [[ -f "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"
fi
antidote load

if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# for _rc in ${ZDOTDIR:-$HOME}/conf.d/*source-antidote.zsh; do
#   # Source non-tilde files.
#     # if [[ $_rc:t != '~'* ]]; then
#     source "$_rc"
# #   fi
# done
# unset _rc
export ZSH=$(antidote path https://github.com/ohmyzsh/ohmyzsh) 
