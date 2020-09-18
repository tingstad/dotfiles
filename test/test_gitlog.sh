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
    lines="$(yes | head)"
    index=1
    length=3
    read_input <<< j
    assertEquals "j (down) should increment pointer" 2 $index
}
test_key_g() {
    index=2
    read_input <<< g
    assertEquals "g (beginning) should reset pointer" 0 $index
}
test_key_G() {
    lines="$(yes | head -n 30)"
    length=20
    read_input <<< G
    assertEquals "G (end) should set pointer to end" 19 $index
}
test_key_G_end() {
    lines="$(yes | head -n 10)"
    length=20
    read_input <<< G
    assertEquals "G (end) should set pointer to end" 9 $index
}
test_key_M() {
    lines="$(yes | head -n 30)"
    length=20
    read_input <<< M
    assertEquals "M should set pointer to middle" 9 $index
}
test_key_k_at_top() {
    index=0
    read_input <<< k
    assertEquals "k (up) should not decrement pointer at start" 0 $index
}
test_key_j_bottom() {
    lines="$(yes | head)"
    index=1
    length=2
    read_input <<< j
    assertEquals "j (down) should not increment pointer at bottom" 1 $index
}
test_key_j_end() {
    lines="$(yes | head -n 2)"
    index=1
    length=9
    read_input <<< j
    assertEquals "j (down) should not increment pointer at bottom" 1 $index
}

DIR=$(cd "$(dirname "$0")"; pwd)
source "$DIR/../gitlog.sh"
set +o errexit
return 2>/dev/null || true
source "$DIR/shunit2.sh"

