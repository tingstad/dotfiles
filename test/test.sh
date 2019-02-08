#!/usr/bin/env bash

TESTMODE="on"

DIR=$(cd "$(dirname "$0")"; pwd)

source "$DIR/test_add_aliases.sh"

source "$DIR/../make.sh"
set +o errexit
source "$DIR/shunit2.sh"

