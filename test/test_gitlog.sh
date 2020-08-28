#!/bin/bash

testThatDrawWritesHeading() {
    local contains=' W E L C O M E'
    assertEquals "$contains" "$(draw | egrep -o "$contains")"
}
test_key_k() {
    index=1
    read_input <<< k
    assertEquals "k (up) should decrement pointer" 0 $index
}
test_key_j() {
    index=1
    length=3
    read_input <<< j
    assertEquals "j (down) should increment pointer" 2 $index
}
test_key_k_at_top() {
    index=0
    read_input <<< k
    assertEquals "k (up) should not decrement pointer at start" 0 $index
}

DIR=$(cd "$(dirname "$0")"; pwd)
source "$DIR/../gitlog.sh"
set +o errexit
return 2>/dev/null || true
source "$DIR/shunit2.sh"

