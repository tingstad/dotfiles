#!/usr/bin/env sh
# Richard H. Tingstad's git GUI
# https://github.com/tingstad/dotfiles
set -e

main() {
    local file="${1:-.}"
    trap 'quit' INT
    #trap 'TODO' WINCH
    command -v tmux >/dev/null || {
        echo "Warning: tmux not found" >&2
    }
    if command -v tmux >/dev/null; then
        if [ -z "$TMUX" ]; then
            tmux new-session -A -s datsgnitlog -n datsgnitlog"$(date +%s)" "$0" "$@"
            exit
        fi
        session="$(tmux display-message -p '#{session_id}')"
        window="$(tmux display-message -p '#{window_id}')"
        window_name="$(tmux display-message -p '#{window_name}')"
        if [ -z "$DATSGNIT_INCEPTION" ] && [[ "$window_name" != datsgnitlog* ]]; then
            tmux set-environment -g DATSGNIT_INCEPTION yes \; new-window -n datsgnitlog"$(date +%s)" "$0" "$@"
            exit
        fi
    fi
    from="HEAD"
    pager="$from"
    index=0
    while true; do
        commit=$(echo "$lines" | nocolors | awk "NR==$index+1 { print \$1 }")
        if [ -n "$TMUX" ] && [ "$(tmux list-panes | wc -l)" -lt 2 ]; then
            tmux split-window -h -d
        fi
        [ -n "$TMUX" ] && tmux respawn-pane -t "$session":"$window".1 -k "GIT_PAGER='less -RX -+F' git show $commit -- \"$file\""
        redraw
        read_input
    done
}

redraw() {
    local cols=$COLUMNS
    local rows=$LINES
    if [ -n "$TMUX" ]; then
        local size="$(tmux display -p '#{pane_height} #{pane_width}')"
        if is_number "${size#* }" && is_number "${size% *}"; then
            cols=${size#* }
            rows=${size% *}
        fi
    fi
    if [ -z "$cols" ]; then
        size=$(stty size)
        cols=${size#* }
        rows=${size% *}
    fi
    if ! is_number "$cols"; then
        echo "Unable to detect window width $cols" >&2
        exit 1
    fi
    height=$((rows - 5))
    lines="$(log "$from" "$file" | head -n $height | ccut "$cols")"
    draw "$cols"
}
draw() {
    local cols="$1"
    local esc=$'\033'
    local reset="${esc}[0m"
    local u="${esc}[4m"
    clear
    echo " W E L C O M E"
    echo "$(echo "$lines" | awk "NR==$index+1 { print \$1 }")" " Keys: j/↓, k/↑, ${u}f${reset}orward page, be${u}g${reset}inning, ${u}H${reset}ome/${u}M${reset}iddle/${u}L${reset}ast line, ${u}r${reset}ebase, ${u}F${reset}ixup, ${u}q${reset}uit" | ccut "$cols"
    echo ""
    echo "$lines"
    cursor_set $((index + 4)) 1
    printf ">"
}

cursor_set() {
    local row="$1"
    local col="$2"
    printf "\033[%s;%sH" "$row" "$col"
}

read_input() {
    local escape_char=$'\033'
    read -rsn1 key # get 1 character
    if [ "$key" = "$escape_char" ]; then
        read -rsn2 key # read 2 more chars
    fi
    case $key in
        'q') quit ;;
        'k')  index_dec ;;
        '[A') index_dec ;;
        'j')  index_inc ;;
        '[B') index_inc ;;
        '[D') echo LEFT ;;
        '[C') echo RIGHT ;;
        'g')  index=0 ;;
        'H')  index=0 ;;
        'L')  index_end ;;
        'M')  index_mid ;;
        'l')  tmux select-pane -R ;;
        'f')  forward_page ;;
        'r')  rebase ;;
        'F')  git commit --fixup="$commit" && GIT_EDITOR=true git rebase -i "$commit"^ ;;
        *) >&2 echo 'ERR bad input'; return ;;
    esac
}

log() {
    local from="$1"
    local file="$2"
    git log --pretty=format:'   %C(auto)%h %cd %d %s' --date=short "$from" \
        --color=always \
        -- "$file"
}
rebase() {
    if [ -n "$TMUX" ]; then
        tmux kill-pane -t "$session":"$window".1 || true
    fi
    git rebase -i "$commit"
}
index_mid() {
    index=$(($(get_index_end) / 2))
}
index_end() {
    index=$(get_index_end)
}
get_index_end() {
    local end=$(echo "$lines" | wc -l)
    [ "$end" -lt $height ] \
        && echo $((end - 1)) \
        || echo $((height - 1))
}
index_inc() {
    if [ "$index" -lt $((height - 1)) ] \
            && [ $((index + 1)) -lt "$(echo "$lines" | wc -l)" ]; then
        index=$((index + 1))
    fi
}
index_dec() {
    if [ $index -gt 0 ]; then
        index=$((index - 1))
    fi
}
forward_page() {
    from=$(echo "$lines" | nocolors | awk "END { print \$1 }")
    pager="$pager $from"
    index=0
}
quit() {
    clear
    [ -n "$TMUX" ] && tmux kill-pane -t "$session":"$window".1
    clear
    exit
}
nocolors() {
    sed $'s,\x1b\\[[0-9;]*[A-Za-z],,g'
}
ccut() {
    awk -v max="$1" -v esc='\033' '#
        # Simulates `cut -c 1-X` for text containing ANSI color codes
        # Richard H. Tingstad  https://github.com/tingstad/dotfiles
        BEGIN {
            pattern = esc "\\[[0-9;]*[A-Za-z]"
            reset = esc "[0m"
        }
        {
        str = $0
        rest = $0
        len = 0
        stripped = 0
        while (1) {
            match(rest, pattern)
            if (RLENGTH == -1 || len + RSTART > max) {
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

is_number() {
    case "$1" in
        *[!0-9]*) false ;;
        [0-9]*) true ;;
        *) false ;;
    esac
}

sourced=0
if [ -n "$ZSH_EVAL_CONTEXT" ]; then
    case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
    [ "$(cd $(dirname -- $0) && pwd -P)/$(basename -- $0)" != "$(cd $(dirname -- ${.sh.file}) && pwd -P)/$(basename -- ${.sh.file})" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
    (return 0 2>/dev/null) && sourced=1
#else # other shells: examine for known shell binary filenames. Detects `sh` and `dash`; add additional shell filenames as needed.
#    case ${0##*/} in sh|dash) sourced=1;; esac
fi

if [ $sourced -eq 0 ]; then
    main "$@"
fi
