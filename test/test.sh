#!/usr/bin/env bash
set -o errexit

TESTMODE="on"

src="$(echo "${BASH_SOURCE[0]}" | grep . || echo "$0")"
DIR="$(cd "$(dirname "$src")"; pwd)"

source "$DIR/test_add_aliases.sh"
source "$DIR/test_link_dotfiles.sh"

testSourceAliasesExitCode() {
    source "$DIR/../aliases.sh"
    assertEquals 0 $?
    if [ "$TRAVIS_OS_NAME" = "linux" ] || docker version >/dev/null  ; then
        assertEquals \
            "| From | --> | To |" \
            "$(echo 'digraph { rankdir=LR; From -> To }' | graph-easy | sed -n 2p)"
        assertEquals \
            "  \"a\": {" \
            "$(cd "$DIR"; echo '{ "a": {"b":1} }' | pretty_json 2 | sed -n 2p)"
        assertEquals \
            "pretty_json" \
            "$(echo 'command -v pretty_json' | bash)"
        convert -size 1x1 canvas:red "$DIR"/img.ppm
        assertEquals \
            "PPM 1x1 1x1+0+0 16-bit" \
            "$(identify "$DIR"/img.ppm | cut -d ' ' -f 2-5)"
    fi
}

testSourceAliasesOutput() {
    local output=$(source "$DIR/../aliases.sh" 2>&1 | grep -v 'No docker found')
    assertEquals "" "$output"
}

return 2>/dev/null || true

source "$DIR/../make.sh"
set +o errexit
source "$DIR/shunit2.sh"

