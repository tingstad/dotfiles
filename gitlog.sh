#!/bin/sh
# Richard H. Tingstad's Git UI
# https://github.com/tingstad/dotfiles
set -e

main() {
    is_tmux || unset TMUX
    file="$1"
    bootstrap "$@"
    from="HEAD"
    pager="$from"
    index=0
    dirty_screen=y
    while true; do
        split_screen_if_not_split
        check_screen_size
        set_state from="$from" index="$index" height="$height" width="$width"
        [ "$(get_state "$state" dirty_git)" = true ] \
            || ! diff_state "$state" "$prev_state" from \
            || [ "$(get_state "$prev_state" height)" -lt "$height" ] \
            && _dirty_git=true || _dirty_git=false
        ! diff_state "$state" "$prev_state" height width \
            && _resized=true || _resized=false
        if [ $_dirty_git = true ]; then
            _gitlog="$(log git "$from" "$file" | head -n $((height*4)))"
        fi
        if [ $_dirty_git = true ] || [ $_resized = true ]; then
            lines="$(printf "%s\n" "$_gitlog" | head -n "$log_height" | awk '{print "  " $0}' | ccut "$width")"
            _end=$(get_index_end)
            if [ $index -gt "$_end" ]; then
                index=$_end
            fi
        fi
        if [ $_dirty_git = true ] || [ "$(get_state "$prev_state" index)" != "$index" ]; then
            commit=$(get_commit "$index")
            if ! [ $_dirty_git = true ]; then
                clear_cursor "$(get_state_value "$prev_state" index)"
            fi
        fi
        if [ $_dirty_git = true ] || [ $_resized = true ]; then
            dirty_screen=y
        fi
        [ -n "$TMUX" ] && [ "$commit" != "$show_commit" ] \
            && tmux respawn-pane -t "$session":"$window".1 \
                -k "GIT_PAGER='less -RX -+F' git show $commit ${file:+ -- \"$file\"}" \
            && show_commit="$commit"
        [ -z "$TMUX" ] && [ "$commit" != "$show_commit" ] && [ $dirty_screen = n ] \
            && draw_commit \
            && show_commit="$commit"
        draw "$width" "$height" "$total_width" "$lines" "$index" "$commit"
        dirty_screen=n
        set_state dirty_git=false
        prev_state="$state"
        read_input
    done
}

bootstrap() {
    check_screen_size
    save_tty_settings
    trap 'quit' INT
    #trap 'TODO' WINCH
    check_dependencies git awk sed head less
    git rev-parse #assert git repository
    if is_tmux; then
        if [ -z "$TMUX" ]; then
            tmux new-session -A -s datsgnitlog -n datsgnitlog"$(date +%s)" "$0" "$@"
            exit
        fi
        session="$(tmux display-message -p '#{session_id}')"
        window="$(tmux display-message -p '#{window_id}')"
        if [ -z "$DATSGNIT_INCEPTION" ]; then
            tmux new-window -n datsgnitlog"$(date +%s)" "export DATSGNIT_INCEPTION=yes; $0 $*; $SHELL -i"
            exit
        fi
    fi
}

split_screen_if_not_split() {
    if [ -n "$TMUX" ] \
    && [ "$(tmux display-message -p '#{window_id}')" = "$window" ] \
    && [ "$(tmux list-panes | line_count)" -lt 2 ]; then
        tmux split-window -h -d
        show_commit=""
    fi
}

check_screen_size() {
    _cols=$COLUMNS
    _rows=$LINES
    if [ -n "$TMUX" ]; then
        _size="$(tmux display -t "$session":"$window".0 -p '#{pane_height} #{pane_width}')"
        if is_number "${_size#* }" && is_number "${_size% *}"; then
            _cols=${_size#* }
            _rows=${_size% *}
        fi
    fi
    if [ -z "$_cols" ]; then
        _size=""
        if [ -z "$height" ]; then # first time
            # stty may fail with 'stty: standard input' if we are too quick (docker)
            _try=0
            while [ $((_try += 1)) -lt 9 ]; do
                _s="$(stty size 2>/dev/null)"
                case "$_s" in
                    *[!0-9\ ]*) ;;  # Only digits and space
                    *\ *\ *) ;;     # Just one space
                    [0-9]*\ [0-9]*) _size="$_s"; break ;;
                esac
                delay 1
            done
        fi
        if [ -z "$_size" ]; then
            _size=$(stty size)
        fi
        _cols=${_size#* }
        _rows=${_size% *}
    fi
    if ! is_number "$_cols"; then
        printf "Unable to detect window width %s\n" "$_cols" >&2
        quit 1
    fi
    _new_height=$_rows
    if [ -n "$TMUX" ]; then
        _new_width=$_cols
    else
        _new_width=$((_cols / 2))
    fi
    if [ "$_new_height" != "$height" ] || [ "$_new_width" != "$width" ]; then
        height=$_new_height
        log_height=$((_new_height - 5))
        width=$_new_width
        total_width=$_cols
    fi
}

draw() {
    width="$1"; height="$2"; total_width="$3"; lines="$4"; index="$5"; commit="$6"
    if [ "$dirty_screen" != "n" ]; then
    _cols="$1"
    _reset="\033[0m"
    _u="\033[4m"
    printf "\033[H\033[J" #clear
    printf " W E L C O M E %s\n" "$(printf '%s\n' "$lines" | awk "NR==$index+1 { print \$2 }")"
    printf "Keys: j/↓, k/↑, " # length: 16
    printf '%b' "${_u}h${_reset}elp, ${_u}f${_reset}orward page, be${_u}g${_reset}inning, ${_u}H${_reset}ome/${_u}M${_reset}iddle/${_u}L${_reset}ast line, ${_u}r${_reset}ebase, ${_u}F${_reset}ixup, ${_u}q${_reset}uit" | ccut "$((_cols - 16))"
    printf '\n'
    printf "%s\n" "$lines"
    if [ -z "$TMUX" ]; then
        _y=0
        _x=$((total_width - width + 1))
        while [ $((_y += 1)) -le "$height" ]; do
            cursor_set "$_y" $_x
            printf '%b' "|$_reset"
        done
        draw_commit
    fi
    fi
    cursor_set $((index + 4)) 1
    printf ">"
}

draw_commit() {
    _x=$((total_width - width + 2))
    _w=$((total_width - _x + 1))
    _y=0; while [ $((_y += 1)) -lt "$height" ]; do
        cursor_set "$_y" $_x
        printf "%${_w}s"
    done
    _y=0
    while read -r _line; do
        [ $((_y += 1)) -ge "$height" ] && break
        cursor_set "$_y" $_x
        printf %s "$_line"
    done <<EOF
$(git show --color=always "$commit" | fold -w $_w)
EOF
    show_commit="$commit"
}

cursor_set() {
    _row="$1"
    _col="$2"
    printf "\033[%s;%sH" "$_row" "$_col"
}

read_input() {
    _escape="27"
    _key=""
    _key="$(read_char 1 10)" # get 1 character
    if [ "$(printf %d "'$_key")" = "$_escape" ]; then
        _key="$(read_char 2)" # read 2 more chars
    fi
    case $_key in
        'q') quit ;;
        'k')  index_dec ;;
        '[A') index_dec ;;
        'j')  index_inc ;;
        '[B') index_inc ;;
        '[D') printf LEFT ;;
        '[C') tmux select-pane -R ;;
        'g')  goto_beginning ;;
        'H')  index=0 ;;
        'L')  index_end ;;
        'M')  index_mid ;;
        'l')  tmux select-pane -R ;;
        'f')  forward_page ;;
        'r')  rebase ;;
        'F')  fixup ;;
        'w')  reword ;;
        'v')  revert ;;
        'e')  edit_commit ;;
        'S')  reset ;;
        'a')  about && dirty_screen=y ;;
        'h')  help && dirty_screen=y ;;
    esac
}

read_char() { # $1:chars #2:timeout?
    [ -n "$2" ] && _min=0 || _min=1
    stty -icanon -echo min $_min ${2:+time $2}
    dd bs=1 count="$1" 2>/dev/null
}

help() {
    printf "\033c" #clear
    _reset=$(printf '\033[0m')
    _bold=$(printf '\033[1m')
    cat <<EOF


                $_bold NAVIGATION $_reset

    j/↓, k/↑    Move down/up
    f           Forward one page
    g           Goto beginning
    H/M/L       Jump to home/middle/last in window
    h           Help
    q           Quit
    a           About

                $_bold MODIFYING $_reset

    r           Rebase --interactive
    w           Rewrite commit message
    v           Revert commit
    F           Fixup (amend) commit with staged changes
    e           Edit commit
    S           Reset --hard

Press any key...
EOF
    read_char 1 >/dev/null
}

about() {
    _col=1
    while [ $_col -le "$width" ]; do
        _row=1
        while [ $_row -le "$height" ]; do
            cursor_set $_row $_col
            printf "%s" " "
            _row=$((_row + 1))
        done
        if [ "$(random 0 4)" -lt 1 ]; then delay 1; fi
        _col=$((_col + 1))
    done

    _col=3
    _row=5
    _rest="Presented by:"
    while [ -n "$_rest" ]; do
        _tail="${_rest#?}"
        _char="${_rest%%"$_tail"}"
        _rest="${_tail}"
        cursor_set $_row $_col
        printf "%s" "$_char"
        delay 1
        _col=$((_col + 1))
        if [ "$_char" = ":" ]; then
            _row=$((_row + 1))
            _rest="Richard Tingstad"
        fi
    done
    _count=3
    while [ $_count -gt 0 ]; do
        cursor_set 8 7
        printf "%s" $_count
        sleep 1
        _count=$((_count - 1))
    done
}

delay() {
    if [ "$1" -lt 1 ]; then
        return
    fi
    stty -icanon -echo min 0 time "$1"
    dd bs=1 count=1 2>/dev/null
}

random() {
    awk -v min="$1" -v max="$2" 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'
}

set_state() {
    while [ "$#" -gt 0 ]; do
        [ -z "$1" ] && \
            continue
        _new_state=""
        while read -r _line; do
            for _word in $_line; do
                if [ "${_word%=*}" = "${1%=*}" ]; then
                    _new_state="$1
$_new_state"
                elif [ -n "$_word" ]; then
                    _new_state="$_word
$_new_state"
                fi
            done
        done <<-EOF
		$state
EOF
        if [ -z "$_new_state" ]; then
            state="$1"
        else
            case "$_new_state" in
                *"$1"*) state="$_new_state" ;;
                *) state="$1
$_new_state" ;;
            esac
        fi
        shift
    done
}

diff_state() {
    _state1="$1"; shift
    _state2="$1"; shift
    if [ $# -eq 0 ]; then
        [ "$_state1" = "$_state2" ]
    else
        # shellcheck disable=SC2048,SC2086
        [ "$(get_state "$_state1" $*)" = "$(get_state "$_state2" $*)" ]
    fi
}

get_state() {
    _state="$1"
    shift
    while [ "$#" -gt 0 ]; do
        [ -z "$1" ] && \
            continue
        get_state_value "$_state" "$1"
        shift
    done
}

get_state_value() {
    # $1: state
    # $2: name
    while IFS= read -r _line; do
        [ "${_line%=*}" = "$2" ] && {
            printf "%s" "${_line#*=}"
            break
        }
    done <<-EOF
	$1
EOF
    printf "\n"
}

full_state() {
    printf "\
from=%s
index=%s
height=%s
width=%s
" "$from" "$index" "$height" "$width"
}

log() {
    _git_cmd="$1"
    _from="$2"
    _file="$3"
    $_git_cmd log --graph --pretty=format:'%C(auto)%h %cd %d %s' --date=short "$_from" \
        --color=always \
        ${_file:+ -- "$_file"}
}

fixup() {
    if [ "$index" -eq 0 ] && [ "$from" = "HEAD" ]; then
        git commit --amend --no-edit
    else
        git commit --fixup="$commit" && GIT_EDITOR=true git_rebase "$commit"^
    fi
    set_state dirty_git=true
    if [ "$from" != "HEAD" ]; then
        goto_beginning
    fi
}

rebase() {
    if [ -n "$TMUX" ]; then
        tmux kill-pane -t "$session":"$window".1 || true
    fi
    clear
    git_rebase "$commit"
    if is_rebasing; then
        printf "Happy rebasing :)\n"
        restore_tty_settings
        exit
    fi
    set_state dirty_git=true
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
        git commit --amend --verbose
    else
        GIT_SEQUENCE_EDITOR="sed -i.old 's/^pick ""$commit""/r ""$commit""/'" git_rebase "$commit"^
    fi
    set_state dirty_git=true
    if [ "$from" != "HEAD" ]; then
        goto_beginning
    fi
}

revert() {
    git revert "$commit"
    set_state dirty_git=true
    goto_beginning
}

reset() {
    if [ -n "$TMUX" ]; then
        tmux kill-pane -t "$session":"$window".1 || true
    fi
    clear
    git reset --hard "$commit"
    set_state dirty_git=true
    goto_beginning
}

edit_commit() {
    if [ -n "$TMUX" ]; then
        tmux kill-pane -t "$session":"$window".1 || true
    fi
    clear
    if [ "$index" -gt 0 ] || [ "$from" != "HEAD" ]; then
        GIT_SEQUENCE_EDITOR="sed -i.old 's/^pick ""$commit""/e ""$commit""/'" git_rebase "$commit"^
    fi
    printf "Happy editing :)\n"
    restore_tty_settings
    exit
}

git_rebase() {
    git rebase -i --autosquash --autostash "$@" || {
        restore_tty_settings
        exit 1
    }
}

goto_beginning() {
    from="HEAD"
    index=0
}

index_mid() {
    _middle=$(($(line_count "$lines") / 2))
    _above=0
    _i=0
    while IFS= read -r _line; do
        case $_line in
            *\**) _is_commit=true ;;
            *) _is_commit=false ;;
        esac
        if [ $_is_commit = true ]; then
            if [ $_i -lt $_middle ]; then
                _above=$_i
            elif [ $_i -gt $_middle ]; then
                if [ $((_i - _middle)) -lt $((_middle - _above)) ]; then
                    index=$_i
                else
                    index=$_above
                fi
                return
            else
                index=$_i
                return
            fi
        fi
        _i=$((_i + 1))
    done <<EOF
$lines
EOF
    index=$_above
}

index_end() {
    index=$(get_index_end)
}

clear_cursor() {
    cursor_set $((${1:-$index} + 4)) 1
    printf " "
}

get_index_end() {
    _i=0
    _max=0
    while IFS= read -r _line; do
        case $_line in
            *\**) _is_commit=true ;;
            *) _is_commit=false ;;
        esac
        if [ $_is_commit = true ]; then
            _max=$_i
        fi
        _i=$((_i + 1))
    done <<EOF
$lines
EOF
    printf "%s" $_max
}

index_inc() {
    if [ "$index" -lt $((log_height - 1)) ] \
            && [ $((index + 1)) -lt "$(line_count "$lines")" ]; then
        _i=0
        while IFS= read -r _line; do
            if [ $_i -gt "$index" ]; then
                case $_line in
                    *\**) _is_commit=true ;;
                    *) _is_commit=false ;;
                esac
                if [ $_is_commit = true ]; then
                    index=$_i
                    break
                fi
            fi
            _i=$((_i + 1))
        done <<EOF
$lines
EOF
    fi
}

index_dec() {
    if [ $index -gt 0 ]; then
        _i=0
        _max=$index
        while IFS= read -r _line; do
            if [ $_i -ge "$index" ]; then
                break
            fi
            case $_line in
                *\**) _is_commit=true ;;
                *) _is_commit=false ;;
            esac
            if [ $_is_commit = true ]; then
                _max=$_i
            fi
            _i=$((_i + 1))
        done <<EOF
$lines
EOF
        index=$_max
    fi
}

forward_page() {
    if [ "$(line_count "$lines")" -lt $log_height ]; then
        return
    fi
    from=$(get_commit "$(get_index_end)")
    pager="$pager $from"
    index=0
}

get_commit() {
    _line="$(printf '%s\n' "$lines" | line_at "${1:-$index}")"
    set -f
    # shellcheck disable=2086
    set -- $_line
    {
    for _w in "$@"; do
        case "$_w" in
            *[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*)
                printf '%b' "$_w"
                break
            ;;
        esac
    done
    set +f
    } | nocolors
}

line_at() {
    awk "NR==$1+1 { print }"
}

quit() {
    restore_tty_settings
    [ -n "$TMUX" ] && tmux kill-window
    cursor_set "$height" 1
    exit "${1:-0}"
}

save_tty_settings() {
    saved_tty_settings="$(stty -g)"
}

restore_tty_settings() {
    [ -n "$saved_tty_settings" ] && stty "$saved_tty_settings"
}

nocolors() {
    # shellcheck disable=SC2039
    if [ 'A' = $'\x41' ] 2>/dev/null # Attempt to check support for $'..' (ANSI-C Quoting)
    then                             # Should be supported by most modern shells
        sed $'s,\x1b\\[[0-9;]*[A-Za-z],,g'
    else
        nocolors_posix
    fi
}

nocolors_posix() {
    _line=""
    while IFS= read -r _line || [ -n "$_line" ]; do
        nocolors_line "$_line"
    done
}
nocolors_line() {
    _rest="$1"
    _result=""
    case "$_rest" in
        *[*) true ;;
        *) _result="$_rest"; _rest="" ;; #skip loop if no [
    esac
    while [ -n "$_rest" ]; do
        _code="$(printf %d "'$_rest")"
        _tail="${_rest#?}"
        _char="${_rest%%"$_tail"}"
        _rest="${_tail}"
        if [ "$_code" = "27" ] # 27 = ESC
        then
            _ansi="$(expr " $_rest" : " \(\[[0-9;]*[A-Za-z]\)")"
            if [ -n "$_ansi" ]; then
                _rest="${_rest##$_ansi}"
                continue
            fi
        fi
        _result="$_result$_char"
    done
    printf "%s\n" "$_result"
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
    _missing=""
    for cmd; do
        if ! does_exist "$cmd"; then
            _missing="$_missing $cmd"
        fi
    done
    [ -z "$_missing" ] || {
        printf "Missing dependencies:%s" "$_missing" >&2
        false
    }
}

is_tmux() {
    does_exist tmux
}

does_exist() {
    >/dev/null 2>&1 command -v "$1"
}

line_count() {
    if [ -z "${1+x}" ]; then
        line_count_stdin
    elif [ -z "$1" ]; then
        printf '%s\n' 0
    else
        line_count_stdin <<EOF
$1
EOF
    fi
}
line_count_stdin() {
    _count=0
    _line=""
    while IFS= read -r _line || [ -n "$_line" ]; do
        _count=$((_count+1))
    done
    printf '%s\n' "$_count"
}

is_number() {
    case "$1" in
        *[!0-9]*) false ;;
        [0-9]*) true ;;
        *) false ;;
    esac
}

if [ -n "$BASH_VERSION" ]; then
    return 0 2>/dev/null || true
fi

main "$@"
