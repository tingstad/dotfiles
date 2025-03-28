
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

export CLICOLOR=1



# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
PROMPT='%n@%m %1~ %1(V.%F{yellow}%v%f .)%2(V.%F{blue}%2v%f .)%(?.%F{green}✓.%F{red}%?)%f %% '
RPROMPT="%*" # Current time of day in 24-hour format, with seconds.

precmd() {
    if [ -n "$start" ]; then
        used=$(( $(date +%s) - $start ))
        if [ ${used:-0} -gt 2 ]; then
            echo >&2 "\\033[2m${used}s after $(date '+%H:%M:%S')\\033[m"
        fi
        start=""
    fi
    branch=$(git branch 2>/dev/null | sed -n 's/^\* //p')
    psvar[1]=$branch
    changes=
    if [ -n "$branch" ]; then
        while read xy; do
            if [ "$xy" != "" ] && [ "$xy" != "??" ] && [ "$xy" != "!!" ]
            then
                changes=$(( ${changes:-0} + 1 ))
            fi
        done <<EOF
$(git status --porcelain=v1 | cut -c1-2)
EOF
    fi
    psvar[2]=$changes
}

preexec() {
    start=$(date +%s)
}

