#!/bin/sh
set -e

main() {
    trap 'quit' INT
    printf '\033[?1000h'
    printf '\033[?1003h'
    save_tty_settings
    x=3
    y=3
    w=10
    h=4
    render $y $x
    while true; do
        _escape="27"
        _key=""
        _key="$(read_char 1)" # get 1 character
        if [ "$(printf %d "'$_key")" = "$_escape" ]; then
            _key="$(read_char 2)" # read 2 more chars
        fi
        case $_key in
            '[M')
                    _event=$(read_char 3)
                    _button="${_event%??}"
                    _coord="${_event#?}"
                    _x="${_coord%?}"
                    _y="${_event#??}"
                    _btn_int=$(printf %d "'$_button")
                    _y_int=$(printf %d "'$_y")
                    _x_int=$(printf %d "'$_x")
                    _row=$((_y_int - 32))
                    _col=$((_x_int - 32))
                    _btn=$((_btn_int - 32))
                    #printf "%d %s %d,%d\n" "$_btn" "$_x" "$_col" "$_row"
                    if [ "$_btn" = "0" ]; then
                        if [ $_col -ge $x ] \
                        && [ $_col -le $((x + w)) ] \
                        && [ $_row -ge $y ] \
                        && [ $_row -le $((y + h)) ]
                        then
                            selected=1
                            offx=$((_col - x))
                            offy=$((_row - y))
                        else
                            selected=""
                        fi
                    elif [ "$_btn" = "3" ] || [ "$_btn" = "32" ]; then
                        if [ -n "$selected" ]; then
                            _x2=$((_col - offx))
                            _y2=$((_row - offy))
                            [ $_x2 -gt 0 ] && x=$_x2
                            [ $_y2 -gt 0 ] && y=$_y2
                        fi
                    fi
                    if [ -n "$selected" ]; then
                        render $y $x
                    fi
                    if [ "$_btn" = "3" ]; then
                        selected=""
                    fi
                ;;
            *) quit ;;
        esac
    done
}

render() {
    _y=$1
    _x=$2
    printf "\033[H\033[J" #clear
    _i=0; while [ $((_i += 1)) -lt "$_y" ]; do
        printf "\n"
    done
    _i=$((_x - 1))
    printf "%${_i}s\033[44m╔════════╗\033[m\n"
    printf "%${_i}s\033[44m║DRAG ME!║\033[m\n"
    printf "%${_i}s\033[44m║%3d,%3d ║\033[m\n" "" $_y $_x
    printf "%${_i}s\033[44m╚════════╝\033[m\n"
}

read_char() { # $1:chars #2:timeout?
    [ -n "$2" ] && _min=0 || _min=1
    stty -icanon -echo min $_min ${2:+time $2}
    dd bs=1 count="$1" 2>/dev/null
}

quit() {
    restore_tty_settings
    printf '\033[?1000h'
    printf '\033[?1003l'
    exit
}

save_tty_settings() {
    saved_tty_settings="$(stty -g)"
}

restore_tty_settings() {
    [ -n "$saved_tty_settings" ] && stty "$saved_tty_settings"
}

main "$@"
