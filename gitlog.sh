#!/usr/bin/env sh
# Richard H. Tingstad's git GUI
# https://github.com/tingstad/dotfiles
set -e

main() {
    local file="$1"
    bootstrap "$@"
    from="HEAD"
    pager="$from"
    index=0
    while true; do
        commit=$(echo "$lines" | nocolors | awk "NR==$index+1 { print \$1 }")
        split_screen_if_not_split
        [ -n "$TMUX" ] && tmux respawn-pane -t "$session":"$window".1 -k "GIT_PAGER='less -RX -+F' git show $commit ${file:+ -- \"$file\"}"
        redraw
        dirty_screen=y
        read_input
    done
}

bootstrap() {
    local file="$1"
    trap 'quit' INT
    #trap 'TODO' WINCH
    check_dependencies git awk sed wc head less
    git rev-parse #assert git repository
    does_exist tmux || {
        echo "Warning: tmux not found" >&2
    }
    if does_exist tmux; then
        if [ -z "$TMUX" ]; then
            tmux new-session -A -s datsgnitlog -n datsgnitlog"$(date +%s)" "$0" "$@"
            exit
        fi
        session="$(tmux display-message -p '#{session_id}')"
        window="$(tmux display-message -p '#{window_id}')"
        if [ -z "$DATSGNIT_INCEPTION" ]; then
            local remain="$(does_exist bash && echo bash || echo sh)"
            tmux new-window -e DATSGNIT_INCEPTION=yes -n datsgnitlog"$(date +%s)" "$0 $@; $remain -i"
            exit
        fi
    fi
}

split_screen_if_not_split() {
    if [ -n "$TMUX" ] && [ "$(tmux list-panes | wc -l)" -lt 2 ]; then
        tmux split-window -h -d
    fi
}
redraw() {
    check_screen_size
    lines="$(log git "$from" "$file" | head -n $height | ccut "$width")"
    draw "$width"
}
check_screen_size() {
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
    local new_height=$((rows - 5))
    local new_width="$cols"
    if [ "$new_height" != "$height" ] || [ "$new_width" != "$width" ]; then
        dirty_screen=y
        height=$((rows - 5))
        width="$cols"
    fi
}
draw() {
    if [ "$dirty_screen" != "n" ]; then
    local cols="$1"
    local esc=$'\033'
    local reset="${esc}[0m"
    local u="${esc}[4m"
    clear
    echo " W E L C O M E"
    echo "$(echo "$lines" | awk "NR==$index+1 { print \$1 }")" " Keys: j/↓, k/↑, ${u}f${reset}orward page, be${u}g${reset}inning, ${u}H${reset}ome/${u}M${reset}iddle/${u}L${reset}ast line, ${u}r${reset}ebase, ${u}F${reset}ixup, ${u}q${reset}uit" | ccut "$cols"
    echo ""
    echo "$lines"
    fi
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
        'j')  clear_cursor && dirty_screen=n && index_inc ;;
        '[B') index_inc ;;
        '[D') echo LEFT ;;
        '[C') echo RIGHT ;;
        'g')  goto_beginning ;;
        'H')  index=0 ;;
        'L')  index_end ;;
        'M')  index_mid ;;
        'l')  tmux select-pane -R ;;
        'f')  forward_page ;;
        'r')  rebase ;;
        'F')  fixup ;;
        'w')  reword ;;
        'e')  edit_commit ;;
        *) >&2 echo 'ERR bad input'; return ;;
    esac
}

log() {
    local git_cmd="$1"
    local from="$2"
    local file="$3"
    $git_cmd log --pretty=format:'   %C(auto)%h %cd %d %s' --date=short "$from" \
        --color=always \
        ${file:+ -- "$file"}
}

fixup() {
    if [ "$index" -eq 0 ] && [ "$from" = "HEAD" ]; then
        git commit --amend --no-edit
    else
        git commit --fixup="$commit" && GIT_EDITOR=true git_rebase "$commit"^
    fi
    goto_beginning
}

rebase() {
    if [ -n "$TMUX" ]; then
        tmux kill-pane -t "$session":"$window".1 || true
    fi
    clear
    git_rebase "$commit"
    if is_rebasing; then
        echo "Happy rebasing :)"
        exit
    fi
    goto_beginning
}

is_rebasing() {
    for f in .git/rebase*; do
        if [ -e "$f" ]; then
            return 0
        fi
    done
    false
}

reword() {
    if [ "$index" -eq 0 ] && [ "$from" = "HEAD" ]; then
        git commit --amend
    else
        GIT_SEQUENCE_EDITOR="sed -i.old 's/^pick "$commit"/r "$commit"/'" git_rebase "$commit"^
    fi
    goto_beginning
}

edit_commit() {
    if [ -n "$TMUX" ]; then
        tmux kill-pane -t "$session":"$window".1 || true
    fi
    clear
    if [ "$index" -gt 0 ] || [ "$from" != "HEAD" ]; then
        GIT_SEQUENCE_EDITOR="sed -i.old 's/^pick "$commit"/e "$commit"/'" git_rebase "$commit"^
    fi
    echo "Happy editing :)"
    exit
}

git_rebase() {
    git rebase -i --autosquash --autostash "$@"
}

goto_beginning() {
    from="HEAD"
    index=0
}

index_mid() {
    index=$(($(get_index_end) / 2))
}
index_end() {
    index=$(get_index_end)
}
clear_cursor() {
    cursor_set $((index + 4)) 1
    printf " "
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
    [ -n "$TMUX" ] && tmux kill-window
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

check_dependencies() {
    local missing=""
    for cmd; do
        if ! does_exist "$cmd"; then
            missing="$missing $cmd"
        fi
    done
    [ -z "$missing" ] || {
        echo "Missing dependencies:$missing" >&2
        false
    }
}

does_exist() {
    >/dev/null 2>&1 command -v "$1"
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
