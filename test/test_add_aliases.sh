#!/bin/bash

testAliasesWhenNoExistingTargetFile() {
    local target_file="none_existing"
    local alias_file="$DIR/../aliases.sh" 

    add_aliases "$alias_file" "$target_file"

    read -r -d '' expected <<- EOF
		source "$alias_file" # TINGSTAD DOTFILES v2
	EOF
    actual="$(cat $target_file)"
    rm "$target_file"
    assertEquals "$expected" "$actual"
}

testAliasesWhenVirginTargetFile() {
    local target_file="virgin_file"
    echo "something" > $target_file
    local alias_file="$DIR/../aliases.sh" 

    add_aliases "$alias_file" "$target_file"

    read -r -d '' expected <<- EOF
		something
		source "$alias_file" # TINGSTAD DOTFILES v2
	EOF
    actual="$(cat $target_file)"
    rm "$target_file"
    assertEquals "$expected" "$actual"
}

testAliasesExistingTargetFile() {
    local target_file="existing_file"
    cat - > $target_file <<- EOF
		before
		some_old_content # TINGSTAD DOTFILES v2
		after
	EOF
    local alias_file="$DIR/../aliases.sh" 

    add_aliases "$alias_file" "$target_file"

    read -r -d '' expected <<- EOF
		before
		source "$alias_file" # TINGSTAD DOTFILES v2
		after
	EOF
    actual="$(cat $target_file)"
    rm "$target_file"
    assertEquals "$expected" "$actual"
}

testAliasesExistingTargetFileV1() {
    local target_file="existing_file"
    cat - > $target_file <<- EOF
		before
		#BEGIN TINGSTAD DOTFILES
		some_old_content
		#END TINGSTAD DOTFILES
		after
	EOF
    local alias_file="$DIR/../aliases.sh"

    add_aliases "$alias_file" "$target_file"

    read -r -d '' expected <<- EOF
		before
		source "$alias_file" # TINGSTAD DOTFILES v2
		after
	EOF
    actual="$(cat $target_file)"
    rm "$target_file"
    assertEquals "$expected" "$actual"
}

testAliasesExistingTargetFileUnknownVersion() {
    local target_file="existing_file"
    cat - > $target_file <<- EOF
		before
		some_content # TINGSTAD DOTFILES v9999
		after
	EOF
    local alias_file="$DIR/../aliases.sh"
    local err="$(mktemp)"

    add_aliases "$alias_file" "$target_file" 2>"$err"

    assertTrue "Should fail" "[ $? -gt 0 ]"
    assertEquals "$(cat "$err")" "ERROR: Unknown TINGSTAD DOTFILES version!"
}

if [ -z "$TESTMODE" ]; then
    TESTMODE="on"
    DIR=$(cd "$(dirname "$0")"; pwd)
    source "$DIR/../make.sh"
    set +o errexit
    source "$DIR/shunit2.sh"
fi

