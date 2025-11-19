# Silence errors and bells
# setopt autocd             # Just type directory name to cd into it
# setopt auto_pushd         # Use pushd instead of cd, maintains dir stack
# setopt pushd_ignore_dups  # Prevent duplicate entries in directory stack
# setopt no_beep            # Don't beep on error
# setopt correct            # Suggest corrections for mistyped commands
# setopt interactive_comments  # Allow comments in interactive shells
# setopt extended_glob      # Enable extended globbing (e.g. **/*.txt)
# setopt no_flow_control    # Avoid Ctrl-S/Ctrl-Q issues
# setopt hist_ignore_dups   # Ignore duplicate history entries
# setopt hist_ignore_space  # Ignore commands that start with a space
# setopt share_history
setopt prompt_subst
      # Share history between terminals
# setopt NO_BEEP
# setopt NO_HIST_BEEP
setopt HIST_IGNORE_ALL_DUPS # remove all earlier duplicate lines
setopt APPEND_HISTORY # history appends to existing file
setopt SHARE_HISTORY # import new commands from the history file also in other zsh-session
setopt EXTENDED_HISTORY # save each commands beginning timestamp and the duration to the history file
setopt HIST_REDUCE_BLANKS # trim multiple insgnificant blanks in history
setopt HIST_IGNORE_SPACE # don’t store lines starting with space
setopt EXTENDED_GLOB # treat special characters as part of patterns
setopt CORRECT_ALL # try to correct the spelling of all arguments in a line
unsetopt FLOW_CONTROL # disable stupid annoying keys
setopt MULTIOS # allows multiple input and output redirections
setopt AUTO_CD # if the command is directory and cannot be executed, perfort cd to this directory
setopt CLOBBER # allow > redirection to truncate existing files
setopt BRACE_CCL # allow brace character class list expansion
unsetopt BEEP # do not beep on errors
unsetopt NOMATCH # try to avoid the 'zsh: no matches found...'
setopt INTERACTIVE_COMMENTS # allow use of comments in interactive code
setopt AUTO_PARAM_SLASH # complete folders with / at end
setopt LIST_TYPES # mark type of completion suggestions
setopt HASH_LIST_ALL # whenever a command completion is attempted, make sure the entire command path is hashed first
setopt COMPLETE_IN_WORD # allow completion from within a word/phrase
setopt ALWAYS_TO_END # move cursor to the end of a completed word
setopt LONG_LIST_JOBS # list jobs in the long format by default
setopt AUTO_RESUME # attempt to resume existing job before creating a new process
setopt NOTIFY # report status of background jobs immediately
unsetopt SHORT_LOOPS # disable short loop forms, can be confusing
unsetopt RM_STAR_SILENT # notify when rm is running with *
setopt RM_STAR_WAIT # wait for 10 seconds confirmation when running rm with *

# a bit fancy than default
# PROMPT_EOL_MARK='%K{red} %k'
# History tweaks
# setopt APPEND_HISTORY
# setopt INC_APPEND_HISTORY
# setopt SHARE_HISTORY
# setopt HIST_IGNORE_DUPS
# setopt HIST_IGNORE_SPACE
# setopt HIST_FIND_NO_DUPS
# setopt HIST_REDUCE_BLANKS

# # Directory behavior
# setopt NO_AUTO_CD
# setopt AUTO_PUSHD
# setopt PUSHD_SILENT
# setopt PUSHD_IGNORE_DUPS

# # Globbing
# setopt NO_NOMATCH
# setopt EXTENDED_GLOB

# Alias hygiene
if (( $+aliases[d] )); then
  unalias d
  alias dirh='dirs -v'
fi

# alias dirh='dirs -v'
# alias pu='pushd'
# alias po='popd'



#
# unprezto - Undo things Prezto did that I don't like
#

# Editor
# setopt NO_BEEP

# # History
# setopt NO_HIST_BEEP

# # Directory
# setopt NO_AUTO_CD
# if (( $+aliases[d] )); then
#   unalias d
#   alias dirh='dirs -v'
# fi
