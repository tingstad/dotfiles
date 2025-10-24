#!/usr/bin/env bash
set -o errexit

TESTMODE="on"

if [ -z "$DIR" ]; then
    src=$(echo "${BASH_SOURCE[0]}" | grep . || echo "$0")
    DIR=$(dirname -- "$src")
    DIR=$(cd -- "$DIR"; pwd)
fi

bin=$(cd -- "$DIR"; cd ../bin/; pwd)
export PATH="$PATH:$bin"

testUnicode() {
    assertEquals \
'2190 ←
2192 →' \
    "$(,unicode ←→)"

    expected=$(printf '1f1e6\n1f1f4') # A O
    assertEquals "$expected" \
        "$(printf %s '🇦🇴' | ,unicode | awk '{ print $1 }')"
}

return 2>/dev/null || true

set +o errexit
source "$DIR/shunit2.sh"

