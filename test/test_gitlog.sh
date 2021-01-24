#!/bin/bash

setUp(){
    [ -z "$TRAVIS_OS_NAME" ] \
        && printf "\033[s" #Save cursor position
}

tearDown(){
    [ -z "$TRAVIS_OS_NAME" ] \
        && printf "\033[u" `#Restore cursor position` && echo
}

testThatDrawWritesHeading() {
    local contains=' W E L C O M E'
    assertEquals "$contains" "$(draw | egrep -o "$contains")"
}

test_key_k() {
    read -r -d '' lines <<- EOF
	  * db334c1 2021-01-21  Commit 1
	  * db334c0 2021-01-20  Commit 0
	EOF
    index=1
    read_input <<< k
    assertEquals "k (up) should decrement pointer" 0 $index
}

test_key_j() {
    read -r -d '' lines <<- EOF
	  * db334c3 2021-01-23  Commit 3
	  * db334c2 2021-01-22  Commit 2
	  * db334c1 2021-01-21  Commit 1
	EOF
    index=1
    height=3
    read_input <<< j
    assertEquals "j (down) should increment pointer" 2 $index
}

test_key_j_k_graph() {
    read -r -d '' lines <<- EOF
	  *   db334c3 2021-01-23  Commit 3
	  |\ 
	  | * db334c2 2021-01-22  Commit 2
	  |/
	  *   db334c1 2021-01-21  Commit 1
	EOF
    height=5
    index=0
    read_input <<< j
    assertEquals "increment index graph" 2 $index
    read_input <<< j
    assertEquals "increment index graph" 4 $index
    read_input <<< k
    assertEquals "decrement index graph" 2 $index
    read_input <<< k
    assertEquals "decrement index graph" 0 $index
}

test_key_g() {
    from=some_commit
    index=2
    read_input <<< g
    assertEquals "g (beginning) should reset pointer" 0 $index
    assertEquals "g (beginning) should reset 'from'" HEAD $from
}

test_key_H() {
    read -r -d '' lines <<- EOF
	  * db334c3 2021-01-23  Commit 3
	  * db334c2 2021-01-22  Commit 2
	  * db334c1 2021-01-21  Commit 1
	EOF
    index=2
    read_input <<< H
    assertEquals "H (Home line) should reset pointer" 0 $index
}

test_key_L() {
    lines=""
    for i in {0..6}; do
        lines="$(printf '%s\n%s' "  * db334c$i 2021-01-2$i  Commit $i" "$lines")"
    done
    read_input <<< L
    assertEquals "L (end) should set pointer to end" 6 $index
}

test_key_L_end() {
    lines=""
    for i in {0..9}; do
        lines="$(printf '%s\n%s' "  * db334c$i 2021-01-2$i  Commit $i" "$lines")"
    done
    height=20
    read_input <<< L
    assertEquals "L (end) should set pointer to end" 9 $index
}

test_key_M() {
    read -r -d '' lines <<- EOF
	  * db334c3 2021-01-23  Commit 3 index0
	  * db334c2 2021-01-22  Commit 2 index1
	  * db334c1 2021-01-21  Commit 1 index2
	EOF
    read_input <<< M
    assertEquals "M should set pointer to middle" 1 $index
}

test_index_mid_even() {
    read -r -d '' lines <<- EOF
	  * db334c3 2021-01-23  Commit 3 index0
	  * db334c2 2021-01-22  Commit 2 index1
	  * db334c1 2021-01-21  Commit 1 index2
	  * db334c0 2021-01-20  Commit 0 index3
	EOF
    index_mid
    assertEquals 2 $index
}

test_index_mid_graph() {
    read -r -d '' lines <<- EOF
	  *   db334c4 2021-01-24  Commit 4 index0
	  *   db334c3 2021-01-23  Commit 3 index1
	  |\ 
	  | * db334c2 2021-01-22  Commit 2 index3
	  |/
	  *   db334c1 2021-01-21  Commit 1 index5
	EOF
    index_mid
    assertEquals "should set index" 3 $index
}

test_index_mid_graph_above() {
    read -r -d '' lines <<- EOF
	  *   db334c3 2021-01-23  Commit 3 index0
	  |\ 
	  | * db334c2 2021-01-22  Commit 2 index2
	  |/
	  *   db334c1 2021-01-21  Commit 1 index4
	  *   db334c0 2021-01-20  Commit 0 index5
	EOF
    index_mid
    assertEquals "should set index" 2 $index
}

test_key_k_at_top() {
    index=0
    read_input <<< k
    assertEquals "k (up) should not decrement pointer at start" 0 $index
}

test_key_j_bottom() {
    read -r -d '' lines <<- EOF
	  * db334c3 2021-01-23  Commit 3
	  * db334c2 2021-01-22  Commit 2
	  * db334c1 2021-01-21  Commit 1
	EOF
    index=1
    height=2
    read_input <<< j
    assertEquals "j (down) should not increment pointer at bottom" 1 $index
}

test_key_j_end() {
    read -r -d '' lines <<- EOF
	  * db334c2 2021-01-22  Commit 2
	  * db334c1 2021-01-21  Commit 1
	EOF
    index=1
    height=9
    read_input <<< j
    assertEquals "j (down) should not increment pointer at bottom" 1 $index
}

test_key_f_forward() {
    pager=('HEAD')
    from='HEAD'
    lines=""
    for i in {1..10}; do
        lines="$(printf '  * 00000%02d 2021-01-01  Commit %d\n%s' $i $i "$lines")"
    done
    index=2
    height=5
    read_input <<< f
    assertEquals "f should set index 0" 0 $index
    assertEquals "f should set HEAD" 0000001 $from
    assertEquals "f should set pager" 'HEAD 0000001' "${pager[*]}"
}

test_check_screen_size() {
    height=""
    width=""
    check_screen_size
    assertTrue "Width" "is_number $width"
}

test_state() {
    state=""
    set_state "index=2"
    assertEquals "index=2" "$state"

    set_state "from=HEAD"
    assertEquals "from=HEAD index=2 " "$(echo "$state" | sort | grep . | tr '\n' ' ')"

    set_state "index=1"
    assertEquals "from=HEAD index=1 " "$(echo "$state" | sort | grep . | tr '\n' ' ')"

    assertEquals "1" "$(get_state "$state" 'index')"
    assertEquals "HEAD" "$(get_state "$state" 'from')"

    set_state one=1 index=3 two=2
    assertEquals "3" "$(get_state "$state" 'index')"
    assertEquals "1" "$(get_state "$state" 'one')"
    assertEquals "2" "$(get_state "$state" 'two')"
    assertEquals $'1\n2' "$(get_state "$state" one two)"
}

test_full_state() {
    from=FROM
    index=4
    height=100
    width=80
    read -r -d '' expected <<- EOF
		from=FROM
		index=4
		height=100
		width=80
		EOF
    assertEquals "$expected" "$(full_state)"
    assertEquals "100" "$(get_state "$expected" height)"
}

test_diff_state() {
    set_state one=1 index=3 two=2
    assertTrue  "diff state state" 'diff_state "$state" "$state"'
    prev="$state"
    set_state index=4
    assertTrue  "diff prev prev"   'diff_state "$prev" "$prev"'
    assertFalse "diff state prev"  'diff_state "$prev" "$state"'
    assertTrue  "diff one"         'diff_state "$prev" "$state" one'
    assertTrue  "diff one two"     'diff_state "$prev" "$state" one two'
    assertFalse "diff index"       'diff_state "$prev" "$state" index'
    assertFalse "diff one index"   'diff_state "$prev" "$state" one index'
    assertFalse "diff index one"   'diff_state "$prev" "$state" index one'
}

test_check_dependencies() {
    assertTrue "dependency awk should exist" "check_dependencies awk"
    assertTrue "dependency sed should exist" "check_dependencies sed"
    assertTrue "dependency sed+awk should exist" "check_dependencies awk sed"
    assertFalse "dependency asdifuwe should not exist" "check_dependencies asdifuwe"
    assertEquals "Missing dependencies: a b" "$(check_dependencies a b 2>&1)"
}

test_is_rebasing() {
    assertFalse "is_rebasing"
}

test_line_count() {
    assertEquals "1" "$(echo hei | line_count)"
    assertEquals "0" "$(printf '' | line_count)"
    assertEquals "2" "$(seq 1 2 | line_count)"
    assertEquals "3" "$(printf '1\n2\n3' | line_count)"
    assertEquals "3" "$(printf '1\n2\n3\n' | line_count)"
}
test_line_count_with_argument() {
    assertEquals "1" "$(line_count "hei")"
    assertEquals "0" "$(line_count "")"
    assertEquals "2" "$(line_count "$(seq 1 2)")"
    assertEquals "3" "$(line_count "$(printf '1\n2\n3')")"
    assertEquals "3" "$(line_count "$(printf '1\n2\n3\n')")"
}

test_is_number() {
    assertFalse "Letter" "is_number A"
    assertFalse "Empty" "is_number ''"
    assertFalse "Letter digit" "is_number c4"
    assertFalse "Digit letter" "is_number 2b"
    assertFalse "Digit letter digit" "is_number 2o3"
    assertFalse "Decimal" "is_number 2.3"
    assertFalse "Punctuation" "is_number 3,"
    assertTrue "Digit" "is_number 1"
    assertTrue "Zero" "is_number 0"
    assertTrue "Tens" "is_number 12"
    assertTrue "Tens higher" "is_number 44"
    assertTrue "Hundreds" "is_number 100"
    assertTrue "Big number" "is_number 1234567"
}
test_ccut() {
    esc="\033"
    red="$esc[0;31m"
    bluish="$esc[38;5;60m"
    reset="$esc[0m"
    str="Default ${red}RED ${bluish}FANCY${reset} Default"
    assertEquals "Trunc" "$(ccut 5 <<< Truncated)"
    assertEquals "Short" "$(ccut 6 <<< Short)"
    assertEquals "Defau" "$(echo -e $str | ccut 5)"
    assertEquals "Default " \
        "$(echo -e $str | ccut 8)"
    assertEquals \
        "$(echo -e "Default ${red}R${reset}")" \
        "$(echo -e $str | ccut 9)"
    assertEquals \
        "$(echo -e "Default ${red}RED ${reset}")" \
        "$(echo -e $str | ccut 12)"
    assertEquals \
        "$(echo -e "Default ${red}RED ${bluish}F${reset}")" \
        "$(echo -e $str | ccut 13)"
    assertEquals \
        "$(echo -e "Default ${red}RED ${bluish}FA${reset}")" \
        "$(echo -e $str | ccut 14)"
    assertEquals \
        "$(echo -e "Default ${red}RED ${bluish}FANCY${reset}")" \
        "$(echo -e $str | ccut 17)"
    assertEquals \
        "$(echo -e "Default ${red}RED ${bluish}FANCY${reset} ${reset}")" \
        "$(echo -e $str | ccut 18)"
    assertEquals \
        "$(echo -e "Default ${red}RED ${bluish}FANCY${reset} D${reset}")" \
        "$(echo -e $str | ccut 19)"
    assertEquals \
        "$(echo -e "$str$reset")" \
        "$(echo -e $str | ccut 99)"
    assertEquals \
        "$(echo -e "${red}RE$reset")" \
        "$(echo -e "${red}RED $reset" | ccut 2)"
    assertEquals \
        "$(echo -e "Minimal$esc[m r$reset")" \
        "$(echo -e "Minimal$esc[m reset code" | ccut 9)"
    assertEquals "Multiple lines" \
        "$(echo -e "one\ntwo")" \
        "$(echo -e "oneS\ntwoS" | ccut 3)"
}

test_nocolors_bash() {
    assertTrue "[ 'A' = $'\x41' ]"
    assert_nocolors nocolors
}

test_nocolors_posix() {
    assert_nocolors nocolors_posix
}

assert_nocolors() {
    local cmd="$1"
    esc="\033"
    red="$esc[0;31m"
    bluish="$esc[38;5;60m"
    reset="$esc[0m"
    str="Default↓ is ${red}RED ${bluish}FANCY${reset} Default"
    assertEquals \
        "newline \\n escaped" \
        "$(printf "%s" "newline \\n escaped" | $cmd)"
    assertEquals "Default↓ is RED FANCY Default" \
        "$(printf "$str" | $cmd)"
    assertEquals \
        "This has no control codes" \
        "$(printf "This has no control codes" | $cmd)"
    assertEquals \
        "$(printf "one\ntwo")" \
        "$(printf "one\ntw${red}o" | $cmd)"
    assertEquals \
        "RE" \
        "$(printf "${red}RE$reset" | $cmd)"
}

test_log() {
    local git_mock=echo
    assertEquals \
        "log --pretty=format:* %C(auto)%h %cd %d %s --date=short HEAD --color=always -- file.txt" \
        "$(log $git_mock HEAD file.txt)"
    assertEquals \
        "log --pretty=format:* %C(auto)%h %cd %d %s --date=short HEAD --color=always" \
        "$(log $git_mock HEAD)"
}

DIR=$(cd "$(dirname "$0")"; pwd)
source "$DIR/../gitlog.sh"
set +o errexit
return 2>/dev/null || true
source "$DIR/shunit2.sh"

