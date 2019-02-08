#!/bin/bash

testAliasesWhenNoExistingTargetFile() {
    file="none_existing"

    add_aliases "$DIR/../aliases.sh" "$file"

    read -r -d '' expected <<- EOF
		#BEGIN TINGSTAD DOTFILES
		#END TINGSTAD DOTFILES
	EOF
    actual="$(sed -n '1p;$p' $file)"
    line_count=$(wc -l $file | egrep -o '[0-9]+')
    rm "$file"
    assertEquals '' "$expected" "$actual"
    assertTrue "[ $line_count -gt 2 ]"
}

testAliasesWhenVirginTargetFile() {
    file="virgin_file"
    echo "something" > $file

    add_aliases "$DIR/../aliases.sh" "$file"

    read -r -d '' expected <<- EOF
		something
		#BEGIN TINGSTAD DOTFILES
		#END TINGSTAD DOTFILES
	EOF
    actual="$(sed -n '1p;2p;$p' $file)"
    line_count=$(wc -l $file | egrep -o '[0-9]+')
    rm "$file"
    assertEquals '' "$expected" "$actual"
    assertTrue "[ $line_count -gt 3 ]"
}

testAliasesExistingTargetFile() {
    file="existing_file"
    cat - > $file <<- EOF
		before
		#BEGIN TINGSTAD DOTFILES
		some_old_content
		#END TINGSTAD DOTFILES
		after
	EOF

    add_aliases "$DIR/../aliases.sh" "$file"

    read -r -d '' expected <<- EOF
		before
		#BEGIN TINGSTAD DOTFILES
		after
	EOF
    actual="$(sed -n '1p;2p;$p;/some_old_content/p' $file)"
    line_count=$(wc -l $file | egrep -o '[0-9]+')
    rm "$file"
    assertEquals '' "$expected" "$actual"
    assertTrue "[ $line_count -gt 4 ]"
}

DIR="$( dirname "$(pwd)/$0" )"
TESTMODE="on"
source "$DIR/../make.sh"
set +o errexit
source "$DIR/shunit2.sh"

