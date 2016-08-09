#!/bin/bash

# inspired by https://github.com/jfrazelle/dotfiles

find -maxdepth 1 \( -name '.*' -or -name gitignore \) -type f -not -name '.*.swp' -not -name '.gitignore' -print \
    | while read f; do
        ln -sf -t ~ $(readlink -f $f)
    done

