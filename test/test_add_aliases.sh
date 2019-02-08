#!/bin/bash

testAliasesWhenNoExistingTargetFile() {
    local target_file="none_existing"
    local alias_file="$DIR/../aliases.sh" 

    add_aliases "$alias_file" "$target_file"

    read -r -d '' expected <<- EOF
		#BEGIN TINGSTAD DOTFILES
		source "$alias_file"
		#END TINGSTAD DOTFILES
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
		#BEGIN TINGSTAD DOTFILES
		source "$alias_file"
		#END TINGSTAD DOTFILES
	EOF
    actual="$(cat $target_file)"
    rm "$target_file"
    assertEquals "$expected" "$actual"
}

testAliasesExistingTargetFile() {
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
		#BEGIN TINGSTAD DOTFILES
		source "$alias_file"
		#END TINGSTAD DOTFILES
		after
	EOF
    actual="$(cat $target_file)"
    rm "$target_file"
    assertEquals "$expected" "$actual"
}

if [ -z "$TESTMODE" ]; then
    TESTMODE="on"
    DIR=$(cd "$(dirname "$0")"; pwd)
    source "$DIR/../make.sh"
    set +o errexit
    source "$DIR/shunit2.sh"
fi

