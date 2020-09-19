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
        height=$[ $(tput lines) - 5 ]
        lines="$(log "$from" "$file" | head -n $height)"
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
        'M')  index_mid ;;
        'l')  tmux select-pane -R ;;
        *) >&2 echo 'ERR bad input'; return ;;
    esac
}

log() {
    local from="$1"
    local file="$2"
    git log --pretty=format:'   %h %cd %s' --date=short "$from" \
        -- "$file" \
        | cut -c 1-$(tput cols)
}
index_mid() {
    index=$[ $(get_index_end) / 2 ]
}
index_end() {
    index=$(get_index_end)
}
get_index_end() {
    local end=$(wc -l <<< "$lines")
    [ $end -lt $height ] \
        && echo $[ $end - 1 ] \
        || echo $[ $height - 1 ]
}
index_inc() {
    if [ $index -lt $[ $height - 1 ] \
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
ccut() {
    awk -v max="$1" -v esc='\033' \
        'BEGIN {
            pattern = esc "\\[[0-9;]*[A-Za-z]"
            reset = (esc "[0m")
        }
        {
        str = $0
        rest = $0
        len = 0
        stripped = 0
        while (1) {
            match(rest, pattern)
            if (RLENGTH == -1) {
                if (len == 0) {
                    print substr($0, 1, max)
                    break
                }
                suffix = (stripped > 0 ? reset : "")
                print substr(str, 1, max + stripped) suffix
                break
            }
            else if (len + RSTART > max) {
                suffix = (stripped > 0 ? reset : "")
                print substr(str, 1, max + stripped) suffix
                break
            }
            else {
                stripped += RLENGTH
                len += RSTART - 1
                rest = substr(rest, RSTART + RLENGTH)
            }
        }
    }'
}

return 2>/dev/null || true

main "$@"
