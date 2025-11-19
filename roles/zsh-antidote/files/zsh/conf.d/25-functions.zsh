#!/bin/zsh
##? lspath - list all directories leading up to a filename; this is useful to see if some permissions are blocking access to a file.
function lspath () {
    emulate -L zsh
    local pathlist
    if [[ "${1}" = "${1##/}" ]]; then
        pathlist=(/ ${(s:/:)PWD} ${(s:/:)1})
    else
        pathlist=(/ ${(s:/:)1})
    fi
    local allpaths=()
    local filepath=${pathlist[0]}
    shift pathlist
    for i in ${pathlist[@]}; do
        allpaths=(${allpaths[@]} ${filepath})
        filepath="${filepath%/}/$i"
    done
    allpaths=(${allpaths[@]} ${filepath})
    ls -ld "${allpaths[@]}"
    # vim: ft=zsh
}
##? lspath - list all open ports depending on command available
function lsopenports () {
    emulate -L zsh
    local pathlist
    if [[ "${1}" = "${1##/}" ]]; then
        pathlist=(/ ${(s:/:)PWD} ${(s:/:)1})
    else
        pathlist=(/ ${(s:/:)1})
    fi
    local allpaths=()
    local filepath=${pathlist[0]}
    shift pathlist
    for i in ${pathlist[@]}; do
        allpaths=(${allpaths[@]} ${filepath})
        filepath="${filepath%/}/$i"
    done
    allpaths=(${allpaths[@]} ${filepath})
    ls -ld "${allpaths[@]}"
    # vim: ft=zsh
}

function cdf() {
  local dir
  dir=$(find ${1:-.} -type d 2>/dev/null | fzf +m) && cd "$dir"
}

function ff() {
  local file
  file=$(fzf --preview 'bat --style=numbers --color=always {}' --height=40%) && ${EDITOR:-nvim} "$file"
}

function bak(){
    local now f
    now=$(date +"%Y%m%d-%H%M%S")
    for f in "$@"; do
      if [[ ! -e "$f" ]]; then
        echo "file not found: $f" >&2
        continue
      fi
      cp -R "$f" "$f".$now.bak
    done
}

function post-autosuggestions() {
    # https://github.com/zsh-users/zsh-autosuggestions

# Set highlight color, default 'fg=8'.
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'
    # Set key bindings.
    if [[ -n "$key_info" ]]; then
      # vi
      bindkey -M viins "$key_info[Control]F" vi-forward-word
      bindkey -M viins "$key_info[Control]E" vi-add-eol
    fi

}
##? https://github.com/zsh-users/zsh-history-substring-search
function post-history-substring-search() {

[[ -v terminfo ]] || zmodload zsh/terminfo
    for keymap in 'emacs' 'viins'; do
      bindkey -M "$keymap" "$terminfo[kcuu1]" history-substring-search-up
      bindkey -M "$keymap" "$terminfo[kcud1]" history-substring-search-down
    done
    
    # Vi
    bindkey -M vicmd "k" history-substring-search-up
    bindkey -M vicmd "j" history-substring-search-down
    
    # Emacs
    if [[ -n "$key_info" ]]; then
      bindkey -M emacs "$key_info[Control]P" history-substring-search-up
      bindkey -M emacs "$key_info[Control]N" history-substring-search-down
    fi
}
##? substenv - substitutes string parts with environment variables
function substenv() {

    if (( $# == 0 )); then
      subenv ZDOTDIR | subenv HOME
    else
      local sedexp="s|${(P)1}|\$$1|g"
      shift
      sed "$sedexp" "$@"
    fi
}

function tailf() {
    local nl
    tail -f $2 | while read j; do
      print -n "$nl$j"
      nl="\n"
    done
}
##? touchf - makes any dirs recursively and then touches a file if it doesn't exist
function touchf() {
    if [[ -n "$1" ]] && [[ ! -f "$1" ]]; then
      mkdir -p "$1:h" && touch "$1"
    fi

}

function update_completions() {
  emulate -L zsh; setopt local_options
  : ${__zsh_config_dir:=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}}
  local destdir=$__zsh_config_dir/completions
  mkdir -p $destdir

  echo "Getting git completions..."
  curl -fsSL -o $destdir/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
  curl -fsSL -o $destdir/_git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh

  echo "Generating starship completions..."
  local _starship=$destdir/_starship
  starship completions zsh >| $_starship
}
# update_completions "$@"

function zcompiledir() {
    emulate -L zsh; setopt localoptions extendedglob globdots globstarshort nullglob rcquotes
    autoload -U zrecompile

    local f
    local flag_clean=false
    [[ "$1" == "-c" ]] && flag_clean=true && shift
    if [[ -z "$1" ]] || [[ ! -d "$1" ]]; then
      echo "Bad or missing directory $1" && return 1
    fi

    if [[ $flag_clean == true ]]; then
      for f in "$1"/**/*.zwc(.N) "$1"/**/*.zwc.old(.N); do
        echo "removing $f" && command rm -f "$f"
      done
    else
      for f in "$1"/**/*.zsh{,-theme}; do
        echo "compiling $f" && zrecompile -pq "$f"
      done
    fi

}
##? wrap-sudo sudo wrapper which is able to expand aliases and handle noglob/nocorrect builtins
function wrap-sudo() {
    # 

    emulate -L zsh

    integer glob=1
    local -a run
    run=(command sudo)
    if [[ ${#} -gt 1 && ${1} = -u ]]; then
        run+=(${1} ${2})
        shift; shift
    fi
    while (( ${#} )); do
        case "${1}" in
            command|exec|-) shift; break ;;
            nocorrect) shift ;;
            noglob) glob=0; shift ;;
            *) break ;;
        esac
    done
    if (( glob )); then
        ${run} $~==*
    else
        ${run} $==*
    fi

    # vim: ft=zsh
}
##? color man without correction suggestions
function wrap-man() {


        emulate -L zsh 

# with new groff we need to explicitly ask for color support
    local -x MANROFFOPT=-c

    # set originally "bold" as "bold and red"
    # set originally "underline" as "underline and green"

    # termcap codes
    # md    start bold
    # mb    start blink
    # me    turn off bold, blink and underline
    # so    start standout (reverse video)
    # se    stop standout
    # us    start underline
    # ue    stop underline
    local -x LESS_TERMCAP_md=$(echoti bold; echoti setaf 1)
    local -x LESS_TERMCAP_mb=$(echoti blink)
    local -x LESS_TERMCAP_me=$(echoti sgr0)
    local -x LESS_TERMCAP_so=$(echoti smso)
    local -x LESS_TERMCAP_se=$(echoti rmso)
    local -x LESS_TERMCAP_us=$(echoti smul; echoti setaf 2)
    local -x LESS_TERMCAP_ue=$(echoti sgr0)

    nocorrect command man ${@}

    # vim: ft=zsh
}

##? cache output of generated compdef
function compdefcache {
emulate -L zsh

setopt local_options extended_glob

local cache_dir="${XDG_CACHE_HOME}/zsh/fpath"
local cache_file="${cache_dir}/_${1##/*}"

# revalidate cache every 20 hours
if [[ -r "${cache_file}" ]] && ! whence ${1} > /dev/null; then
    # remove cache file when it's present, but arg isn't executable
    echo "compdefcache ERROR: $1 isn't executable, removing cache file" >&2
    zf_rm -f "${cache_file}"
elif [[ ! -e "${cache_file}" || -n "${cache_file}"(#qN.mh+20) ]]; then
    # revalidate cache every 20 hours
    # cache miss, create compdef file
    if (( ${+commands[${1}]} )); then
        zf_mkdir -p "${cache_dir}"
        command "$@" > "${cache_file}"
    else
        echo "compdefcache ERROR: $1 is not available in PATH" >&2
    fi
else
    # cache hit, do nothing
fi

# vim: ft=zsh
}

function ineachdir() {
    # do something in each subdirectory of current directory

emulate -L zsh

{
    setopt localoptions localtraps

    # handle Ctrl+C interrupts
    TRAPINT () {
        echo ${fg[white]}"--- IED: Caught SIGINT, aborting."${fg[default]}
        return $(( 128 + $1 ))
    }

    local cwd dir exitcode ied_opts
    local -A ied_status
    cwd=${PWD}

    zparseopts -E -D -M -A ied_opts -- -ignore-errors -status-table i=-ignore-errors s=-status-table

    if [[ ${#} -eq 0 ]]; then
        cat <<- EOH
Usage: ineachdir [-i | --ignore-errors] [-s | --status-table] <command>

Perform specified <command> in each directory.

Arguments:
-i, --ignore-errors    Ignore <command> execution error,
                       continue to next dir

-s, --status-table     Show status table at the end

Example:
ineachdir -s git pull --prune
EOH
        return 0
    fi

    for dir in */; do
        echo ${fg[white]}"--- IED: Executing '$@' in '${cwd}/${dir}'..."${fg[default]}
        cd "${cwd}/${dir}"
        $@
        exitcode=$?
        if (( ${+ied_opts[--status-table]} )); then
            ied_status[${dir}]=${exitcode}
        fi
        if [[ ${exitcode} -ne 0 ]]; then
            if (( ${+ied_opts[--ignore-errors]} )); then
                echo ${fg[yellow]}"--- IED: '$@' returned ${exitcode}, ignoring."${fg[default]}
            else
                echo ${fg[red]}"--- IED: '$@' returned ${exitcode}, aborting."${fg[default]}
                return $(( 128 + ${exitcode} ))
            fi
        fi
        echo
    done

    if (( ${+ied_opts[--status-table]} )); then
        echo ${fg[white]}"--- IED: Execution results"${fg[default]}
        for dir exitcode in ${(kv)ied_status}; do
            if [[ ${exitcode} -ne 0 ]]; then
                exitcode="${fg[yellow]}${exitcode}${fg[default]}"
            fi
            printf '%s\n' "${(r:35:)dir}: ${(%)exitcode}"
        done
    fi
} always {
    cd "${cwd}"
    unfunction TRAPINT
}

# vim: ft=zsh
}

##? recursively search for string, feed matches to fzf with preview, launch vim with selected match
function bag() {

emulate -L zsh

# use bat, if it's available...
local preview_cmd
if (( ${+commands[bat]} )); then
    preview_cmd='bat --style=numbers --color=always --highlight-line=${2} ${1}'
else
    # ...otherwise just highlight line with match using sed replace
    preview_cmd='sed -E "s/(.*'${*}'.*)/'$bg[grey]'\1'$reset_color'/gI;" < ${1}'
fi

# prefer rg over ag over grep
if (( ${+commands[rg]} )); then
    command rg --no-heading --line-number --smart-case --fixed-strings --color=always "${*}"
elif (( ${+commands[ag]} )); then
    command ag --nogroup --color --silent "${*}"
else
    command grep --line-number --recursive --ignore-case --color=always --no-messages "${*}"
fi | fzf --ansi --layout=reverse-list --no-sort --height=50% --delimiter=: \
         --preview=${preview_cmd} \
         --preview-window='right,50%,+{2}/2' \
         --bind='enter:become(${EDITOR} {1} +{2})'

# vim: ft=zsh
}


##? envdiff - compare current env to a clean login shell
function envdiff() {
  diff <(env | sort) <(zsh -lic 'env' | sort) | less
}


function listallparameters() {
zmodload zsh/parameter
print -l ${(k)parameters}
# print -l ${(k)modules}
# print -l ${(k)options}

}
