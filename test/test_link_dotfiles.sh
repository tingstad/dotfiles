#!/bin/bash

testEmptyTargetDir() {
    local target_dir="$(mktemp -d)"

    link_dotfiles "$DIR/.." "$target_dir"

    assertTrue "Links .gitconfig" "[ -L \"$target_dir\"/.gitconfig ]"
    assertTrue "Links .vimrc" "[ -L \"$target_dir\"/.vimrc ]"
    assertTrue "Links .tmux.conf" "[ -L \"$target_dir\"/.tmux.conf ]"
    rm -r "$target_dir"
}

if [ -z "$TESTMODE" ]; then
    TESTMODE="on"
    DIR=$(cd "$(dirname "$0")"; pwd)
    source "$DIR/../make.sh"
    set +o errexit
    source "$DIR/shunit2.sh"
fi

