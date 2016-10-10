#!/bin/bash

# inspired by https://github.com/jfrazelle/dotfiles

find -maxdepth 1 \( -name '.*' -or -name gitignore \) -type f -not -name '.*.swp' -not -name '.gitignore' -print \
    | while read f; do
        fil=~/$(basename $f)
        [ -e $fil -a ! -L $fil ] && cp -L $fil $fil.old
        ln --symbolic --force --target-directory="$HOME" "$(readlink --canonicalize $f)"
    done

