#!/bin/bash

testAliasesWhenNoExistingTargetFile() {
    local file="none_existing"

    local alias_file="$DIR/../aliases.sh" 
    add_aliases "$alias_file" "$file"

    read -r -d '' expected <<- EOF
		#BEGIN TINGSTAD DOTFILES
		source "$alias_file"
		#END TINGSTAD DOTFILES
	EOF
    actual="$(cat $file)"
    line_count=$(wc -l $file | egrep -o '[0-9]+')
    rm "$file"
    assertEquals "$expected" "$actual"
    assertTrue "[ $line_count -gt 2 ]"
}

testAliasesWhenVirginTargetFile() {
    local file="virgin_file"
    echo "something" > $file

    local alias_file="$DIR/../aliases.sh" 
    add_aliases "$alias_file" "$file"

    read -r -d '' expected <<- EOF
		something
		#BEGIN TINGSTAD DOTFILES
		source "$alias_file"
		#END TINGSTAD DOTFILES
	EOF
    actual="$(cat $file)"
    line_count=$(wc -l $file | egrep -o '[0-9]+')
    rm "$file"
    assertEquals "$expected" "$actual"
    assertTrue "[ $line_count -gt 3 ]"
}

testAliasesExistingTargetFile() {
    local file="existing_file"
    cat - > $file <<- EOF
		before
		#BEGIN TINGSTAD DOTFILES
		some_old_content
		#END TINGSTAD DOTFILES
		after
	EOF
    local alias_file="$DIR/../aliases.sh" 

    add_aliases "$alias_file" "$file"

    read -r -d '' expected <<- EOF
		before
		#BEGIN TINGSTAD DOTFILES
		source "$alias_file"
		#END TINGSTAD DOTFILES
		after
	EOF
    actual="$(cat $file)"
    rm "$file"
    assertEquals "$expected" "$actual"
}

DIR="$( dirname "$(pwd)/$0" )"
TESTMODE="on"
source "$DIR/../make.sh"
set +o errexit
source "$DIR/shunit2.sh"

