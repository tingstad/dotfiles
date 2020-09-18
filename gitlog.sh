#!/bin/bash
set -e


main() {
    local file="${1:-.}"
    trap 'echo SIGINT; quit' SIGINT
    trap 'echo SIGWINCH' SIGWINCH
    command -v tmux >/dev/null || {
        echo "tmux not found :(" >&2
        exit 1
    }
    if [ -z "$TMUX" ]; then
        tmux new-session -A -s datsgnitlog -n datsgnitlog"$(date +%s)" "$0"
        exit
    fi
    session="$(tmux display-message -p '#S')"
    window="$(tmux display-message -p '#W')"
    if [[ "$window" != datsgnitlog* ]]; then
        tmux new-window -n datsgnitlog"$(date +%s)" "$0" "$@"
        exit
    fi
    tmux split-window -h -d
    from="HEAD"
    index=0
    while true; do
        length=$[ $(tput lines) - 5 ]
        lines="$(log "$from" $length "$file")"
        draw
        commit=$(echo "$lines" | awk "NR==$index+1 { print \$1 }")
        #tmux send-keys -t 0:"$window".1 C-z "git log $commit" Enter
        tmux respawn-pane -t "$session":"$window".1 -k "GIT_PAGER='less -RX -+F' git show $commit -- \"$file\""
        read_input
    done
}

draw() {
    clear
    echo " W E L C O M E"
    echo "$(echo "$lines" | awk "NR==$index+1 { print \$1 }")"
    echo ""
    echo "$lines"
    cursor_set $[ index + 4 ] 1
    echo -en ">"
}

cursor_set() {
    local row="$1"
    local col="$2"
    echo -en "\033[$row;${col}H"
}

read_input() {
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
        'g')  index=0 ;;
        'G')  index_end ;;
        'M')  index=$[ $[ $length - 1 ] / 2 ] ;;
        'l')  tmux select-pane -R ;;
        *) >&2 echo 'ERR bad input'; return ;;
    esac
}

log() {
    local from="$1"
    local length="$2"
    local file="$3"
    git log --pretty=format:'   %h %cd %s' --date=short "$from" \
        -- "$file" \
        | cut -c 1-$(tput cols) \
        | head -n $length
}

index_end() {
    local end=$(wc -l <<< "$lines")
    if [ $end -lt $length ]; then
        index=$[ $end - 1 ]
    else
        index=$[ $length - 1 ]
    fi
}
index_inc() {
    if [ $index -lt $[ $length - 1 ] \
            -a $[ $index + 1 ] -lt $(wc -l <<< "$lines") ]; then
        index=$[ $index + 1 ]
    fi
}
index_dec() {
    if [ $index -gt 0 ]; then
        index=$[ $index - 1 ]
    fi
}
quit() {
    clear
    tmux kill-window
    exit
}

return 2>/dev/null || true

main "$@"
