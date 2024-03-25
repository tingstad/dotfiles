#!/usr/bin/env bash
set -o errexit

TESTMODE="on"

src="$(echo "${BASH_SOURCE[0]}" | grep . || echo "$0")"
DIR="$(cd "$(dirname "$src")"; pwd)"

bash "$DIR/photosort/photosort-test.sh"
source "$DIR/test_add_aliases.sh"
source "$DIR/test_link_dotfiles.sh"
source "$DIR/test_gitlog.sh"

testSourceAliasesExitCode() {
    source "$DIR/../aliases.sh"
    assertEquals "Exit code source alias.sh" 0 $?
    assertEquals \
        "Should trunc" \
        "$(bash -c 'echo "Should truncate" | ccut 12')"
    assertEquals "1.5" "$(calc 3 / 2)"
    assertEquals "1" "$(seq 3 | drop 2)"
    if [ "$TRAVIS_OS_NAME" = "linux" ] || docker version >/dev/null ; then
        assertEquals "ShellCheck - shell script analysis tool" \
                     "$(shellcheck -V | sed '2,$d')"
        shellcheck "$DIR/../bin/,gitlog"
        assertTrue "ShellCheck passed ($?)" "[ $? -eq 0 ]"
        assertEquals \
            "Apache Maven 3.6.0 Java version: 1.8.0 " \
            "$(bash -c 'mvn_8 -v' \
                | egrep -o --color=never '(Apache|Java)[^0-9]*[0-9.]*' \
                | tr '\n' ' ')"
        assertEquals \
            "Apache Maven 3.6.3 Java version: 11.0.10 " \
            "$(bash -c 'mvn_11 -v' \
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
        assertEquals "node8" \
            "v8.15.0" \
            "$(echo 'node8 -v' | bash)"
        if [ "$(type npx | head -n1)" = "npx is a function" ]; then
        assertEquals "npx" \
            "6.14.7" \
            "$(echo 'npx -v' | bash)"
        fi
        assertEquals "python" "3.8.3" "$(bash -c 'python_docker -V' | sed 's/[^0-9.]//g')"
        assertEquals "swagger" "v0.29.0" \
            "$(bash -c 'swagger version' | awk '/^version:/{print $2}')"
    fi
}

testSourceAliasesOutput() {
    local output=$(source "$DIR/../aliases.sh" 2>&1 | grep -v 'No docker found')
    assertEquals "" "$output"
}

return 2>/dev/null || true

source "$DIR/../install.sh"
set +o errexit
source "$DIR/shunit2.sh"

