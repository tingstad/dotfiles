#!/bin/sh
set -e

# https://stackoverflow.com/a/30133294 by mklement0, License - CC BY-SA 4.0
awk 'BEGIN {srand(); OFMT="%.17f"} {print rand(), $0}' "$@" \
    | sort -k1,1n \
    | cut -d ' ' -f2-

#tmpdir=${TMPDIR:-/tmp}
#tmpdir=${tmpdir%/}
#
#test -f "$1"
#
#n=$(wc -l "$1" | awk '{ print $1 }')
#
#tmp=${tmpdir}/${1}$$
#
#i=$n
#while [ $i -gt 0 ]; do
#    awk 'BEGIN     { srand('$RANDOM'); v = int(rand() * '$i') + 1 }
#        NR == v    { s = $0; next }
#                   { print $0 }
#        END        { print s }' \
#        <"$1" >"$tmp" && mv "$tmp" "$1"
#    i=$(( i - 1 ))
#done
