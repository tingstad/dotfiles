#!/bin/sh
set -e

tmpdir=${TMPDIR:-/tmp}
tmpdir=${tmpdir%/}

test -f "$1"

n=$(wc -l "$1" | awk '{ print $1 }')

tmp=${tmpdir}/${1}$$

i=$n
while [ $i -gt 0 ]; do
    awk 'BEGIN     { srand('$RANDOM'); v = int(rand() * '$i') + 1 }
        NR == v    { s = $0; next }
                   { print $0 }
        END        { print s }' \
        <"$1" >"$tmp" && mv "$tmp" "$1"
    i=$(( i - 1 ))
done

