#!/bin/sh
# Richard H. Tingstad
set -e

set -- $(stty size <&2 2>/dev/null)
rows=${1:-25}
cols=${2:-80}

set --
j=0
while [ $((j+=1)) -le $cols ]; do
    set $@ $((RANDOM % 8))
done
offsets=$@

printf '\033[48;2;30;30;30m' # set background color 1e1e1e
printf '\033[H\033[J'        # move to top and clear
i=0
while [ $((i+=1)) -le $rows ]; do
    set $offsets
    j=0
    while [ $((j+=1)) -le $cols ]; do
        set $@ $1  # iterate over column offsets
        shift      # $1 is current
        printf '\033[38;5;%dm' $((52 + (i+$1) % 7)) # set color to palette N
        printf "$(printf '\\%03o' $((RANDOM % 95 + 32)) )" # ASCII 32-126
    done
    printf \\n
done

set ccffcc 00ff00 00cc00 009900 006600 003300 000000

while true; do
    set $@ $1
    shift
    i=0
    for color; do
        printf '\033]4;%d;#%s\007' $((58-i)) $color  # change color
        i=$(( i + 1 ))
    done
    sleep 0.1
done

