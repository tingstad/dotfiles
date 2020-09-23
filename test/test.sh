#!/usr/bin/env bash
set -o errexit

TESTMODE="on"

src="$(echo "${BASH_SOURCE[0]}" | grep . || echo "$0")"
DIR="$(cd "$(dirname "$src")"; pwd)"

source "$DIR/test_add_aliases.sh"
source "$DIR/test_link_dotfiles.sh"
source "$DIR/test_gitlog.sh"

testSourceAliasesExitCode() {
    source "$DIR/../aliases.sh"
    assertEquals 0 $?
    assertEquals \
        "Should trunc" \
        "$(bash -c 'echo "Should truncate" | ccut 12')"
    if [ "$TRAVIS_OS_NAME" = "linux" ] || docker version >/dev/null ; then
        assertEquals \
            "Apache Maven 3.6.0 Java version: 1.8.0 " \
            "$(bash -c 'mvn_8 -v' \
                | egrep -o --color=never '(Apache|Java)[^0-9]*[0-9.]*' \
                | tr '\n' ' ')"
        assertEquals \
            "| From | --> | To |" \
            "$(echo 'digraph { rankdir=LR; From -> To }' | graph-easy | sed -n 2p)"
        assertEquals \
            "  \"a\": {" \
            "$(cd "$DIR"; echo '{ "a": {"b":1} }' | pretty_json 2 | sed -n 2p)"
        assertEquals \
            "pretty_json" \
            "$(echo 'command -v pretty_json' | bash)"
        convert -size 1x1 canvas:red img.ppm
        assertEquals \
            "PPM 1x1 1x1+0+0 16-bit" \
            "$(identify img.ppm | cut -d ' ' -f 2-5)"
        rm img.ppm
        assertEquals \
            "v8.15.0" \
            "$(echo 'node8 -v' | bash)"
        assertEquals \
            "6.14.7" \
            "$(echo 'npx -v' | bash)"
        assertEquals "3.8.3" "$(bash -c 'python -V' | sed 's/[^0-9.]//g')"
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

