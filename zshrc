
local src_dir=$(cd "$(dirname "$0")"; pwd)
export PATH="$PATH:$src_dir/bin"

setopt APPEND_HISTORY       # Append instead of overwriting
setopt INC_APPEND_HISTORY   # Add commands to history immediately
setopt HIST_IGNORE_DUPS     # Ignore duplicate commands
setopt HIST_REDUCE_BLANKS   # Remove unnecessary blanks
# Share history across all sessions
# Implies EXTENDED_HISTORY which adds timestamps
#setopt SHARE_HISTORY

export HISTFILE=~/.zsh_history
export HISTSIZE=999999999
export SAVEHIST=$HISTSIZE

precmd() {
    [ $? -eq 0 ] && printf '\033[32m'$? || printf '\033[91m'$?
    if [ -n "$start" ]; then
        echo >&2 "\\033[0;2m after $(( $(date +%s) - $start ))s\\033[m"
        start=""
    fi
}

preexec() {
    echo >&2 "\\033[2m$(date '+%H:%M:%S')\\033[0m"
    start=$(date +%s)
}

