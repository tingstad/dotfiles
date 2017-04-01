#!/bin/bash
set -o errexit

# inspired by https://github.com/jfrazelle/dotfiles

ABSPATH=$(cd "$(dirname "$0")"; pwd)

find "$ABSPATH" -maxdepth 1 \( -name '.*' -or -name gitignore \) -type f -not -name '.*.swp' -not -name '.gitignore' -print \
    | while read f; do
        fil="$HOME/$(basename "$f")"
        [ -e "$fil" -a ! -L "$fil" ] && cp -L "$fil" "$fil.old"
        ln -s -f "$f" "$fil"
    done

