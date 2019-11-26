#!/usr/bin/env bash
set -o errexit

TESTMODE="on"

DIR=$(cd "$(dirname "$0")"; pwd)

source "$DIR/test_add_aliases.sh"
source "$DIR/test_link_dotfiles.sh"

testSourceAliasesExitCode() {
    source "$DIR/../aliases.sh"
    assertEquals 0 $?
    if [ "$TRAVIS_OS_NAME" = "linux" ]; then
        assertEquals \
            "| From | --> | To |" \
            "$(echo 'digraph { rankdir=LR; From -> To }' | graph-easy | sed -n 2p)"
    fi
}

testSourceAliasesOutput() {
    local output=$(source "$DIR/../aliases.sh" 2>&1 | grep -v 'No docker found')
    assertEquals "" "$output"
}

source "$DIR/../make.sh"
set +o errexit
source "$DIR/shunit2.sh"

