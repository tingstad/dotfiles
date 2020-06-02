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
            "Apache Maven 3.6.0 Java version: 1.8.0 " \
            "$(bash -c 'mvn8 -v' \
                | egrep -o --color=never '(Apache|Java)[^0-9]*[0-9.]*' \
                | tr '\n' ' ')"
        assertEquals \
            "| From | --> | To |" \
            "$(echo 'digraph { rankdir=LR; From -> To }' | graph-easy | sed -n 2p)"
        assertEquals \
            '  "a": {' \
            "$(cd "$DIR"; echo '{ "a": {"b":1} }' | pretty_json 2 | sed -n 2p)"
        assertEquals \
            "pretty_json" \
            "$(echo 'command -v pretty_json' | bash)"
        convert -size 1x1 canvas:red "$DIR"/img.ppm
        assertEquals \
            "PPM 1x1 1x1+0+0 16-bit" \
            "$(identify "$DIR"/img.ppm | cut -d ' ' -f 2-5)"
        assertEquals \
            "v8.15.0" \
            "$(echo 'node8 -v' | bash)"
    fi
}

testSourceAliasesOutput() {
    local output=$(source "$DIR/../aliases.sh" 2>&1 | grep -v 'No docker found')
    assertEquals "" "$output"
}

testUpdateNoFile() {
    local dir="$(mktemp -d)"
    local file="$dir/$(date -I).lock"
    check_updates_dotfiles "$dir"
    assertTrue "[ -e "$file" ]"
}

testUpdateExistingFile() {
    local dir="$(mktemp -d)"
    local file="$dir/$(date -I).lock"
    echo "You should update" > "$file"
    local output=$(check_updates_dotfiles "$dir")
    assertEquals "$output" "You should update"
    assertTrue "[ -e "$file" ]"
}

testUpdateOldFile() {
    local dir="$(mktemp -d)"
    local file="$dir/$(date -I -d 'now - 1 day').lock"
    check_updates_dotfiles "$dir"
    assertFalse "[ -e "$file" ]"
}

return 2>/dev/null || true

source "$DIR/../make.sh"
set +o errexit
source "$DIR/shunit2.sh"

