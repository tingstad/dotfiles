#!/bin/bash
set -e


function main() {
    trap 'echo SIGINT; quit' SIGINT
    trap 'echo SIGWINCH' SIGWINCH
    command -v tmux >/dev/null
    if [ -z "$TMUX" ]; then
        tmux new-session -A -s datsgnitlog -n datsgnitlog"$(date +%s)" "$0"
        exit
    fi
    session="$(tmux display-message -p '#S')"
    window="$(tmux display-message -p '#W')"
    if [[ "$window" != datsgnitlog* ]]; then
        tmux new-window -n datsgnitlog"$(date +%s)" "$0"
        exit
    fi
    tmux split-window -h -d
    from="HEAD"
    index=0
    while true; do
        length=$[ $(tput lines) - 5 ]
        lines="$(log "$from" $length)"
        draw
        commit=$(echo "$lines" | awk "NR==$index+1 { print \$1 }")
        #tmux send-keys -t 0:"$window".1 C-z "git log $commit" Enter
        tmux respawn-pane -t "$session":"$window".1 -k "GIT_PAGER='less -RX -+F' git show $commit"
        read_input
    done
}

function draw() {
    clear
    echo " W E L C O M E"
    echo "$(echo "$lines" | awk "NR==$index+1 { print \$1 }")"
    echo ""
    echo "$lines"
    cursor_set $[ index + 4 ] 1
    echo -en ">"
}

function cursor_set() {
    local row="$1"
    local col="$2"
    echo -en "\033[$row;${col}H"
}

function read_input() {
    local escape_char=$(printf "\u1b")
    read -rsn1 mode # get 1 character
    if [[ $mode == $escape_char ]]; then
        read -rsn2 mode # read 2 more chars
    fi
    case $mode in
        'q') quit ;;
        'k')  index_dec ;;
        '[A') index_dec ;;
        'j')  index_inc ;;
        '[B') index_inc ;;
        '[D') echo LEFT ;;
        '[C') echo RIGHT ;;
        *) >&2 echo 'ERR bad input'; return ;;
    esac
}

function log() {
    local from="$1"
    local length="$2"
    git log --pretty=format:'   %h %cd %s' --date=short "$from" \
        | cut -c 1-$(tput cols) \
        | head -n $length
}

function index_inc() {
    if [ $index -lt $[ $length - 1 ] ]; then
        index=$[ $index + 1 ]
    fi
}
function index_dec() {
    if [ $index -gt 0 ]; then
        index=$[ $index - 1 ]
    fi
}
function quit() {
    clear
    tmux kill-window
    exit
}

main "$@"
