
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

PROMPT="%n@%m %1~ %(?.%F{green}✓.%F{red}%?)%f %v %% "

precmd() {
    if [ -n "$start" ]; then
        used=$(( $(date +%s) - $start ))
        if [ ${used:-0} -gt 2 ]; then
            echo >&2 "\\033[2m${used}s after $(date '+%H:%M:%S')\\033[m"
        fi
        start=""
    fi
    branch=$(git branch 2>/dev/null | sed -n 's/^\* //p')
    if [ -n "$branch" ]; then
        psvar[1]="$branch"
    fi
}

preexec() {
    start=$(date +%s)
}

