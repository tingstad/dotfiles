#!/usr/bin/env bash
set -o errexit

TESTMODE="on"

DIR=$(cd "$(dirname "$0")"; pwd)

source "$DIR/test_add_aliases.sh"
source "$DIR/test_link_dotfiles.sh"

testSourceAliasesExitCode() {
    source "$DIR/../aliases.sh"
    assertEquals 0 $?
}

testSourceAliasesOutput() {
    local output=$(source "$DIR/../aliases.sh" 2>&1)
    assertEquals "" "$output"
}

source "$DIR/../make.sh"
set +o errexit
source "$DIR/shunit2.sh"

