#!/bin/bash
set -o errexit

# inspired by https://github.com/jfrazelle/dotfiles

ABSPATH=$(cd "$(dirname "$0")"; pwd)

main() {
    link_dotfiles
    add_aliases "$ABSPATH/aliases.sh" "$HOME/.bashrc"
}

link_dotfiles() {
    find "$ABSPATH" -maxdepth 1 \
    \( -name '.*' -or -name gitignore \) \
    -type f \
    -not -name '.*.swp' -not -name '.gitignore' -not -name .bashrc \
    -print \
    | while read f; do
        fil="$HOME/$(basename "$f")"
        [ -e "$fil" -a ! -L "$fil" ] && cp -L "$fil" "$fil.old"
        ln -s -f "$f" "$fil"
    done
}

add_aliases() {
    local alias_file="$1"
    local dest="$2"
    local head="#BEGIN TINGSTAD DOTFILES"
    local tail="#END TINGSTAD DOTFILES"
    if [ -f "$dest" ] && grep -q "$head" "$dest"; then
        { rm "$dest" && \
        awk '/'"$head"'/{ skip=1;print } /'"$tail"'/{ skip=0; print "source \"'"$alias_file"'\""  } !skip{ print }' \
        > "$dest"; } < "$dest"
    else
        echo "$head" >> "$dest"
        echo "source \"$alias_file\"" >> "$dest"
        echo "$tail" >> "$dest"
    fi
}

if [ "$TESTMODE" = "on" ]; then
    return
fi

main

