#!/bin/bash

testThatDrawWritesHeading() {
    local contains=' W E L C O M E'
    assertEquals "$contains" "$(draw | egrep -o "$contains")"
}

DIR=$(cd "$(dirname "$0")"; pwd)
source "$DIR/../gitlog.sh"
set +o errexit
return 2>/dev/null || true
source "$DIR/shunit2.sh"

