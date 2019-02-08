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
    src="$1"
    file="$2"
    head="#BEGIN TINGSTAD DOTFILES"
    tail="#END TINGSTAD DOTFILES"
    if [ -f "$file" ] && grep -q "$head" "$file"; then
        { rm "$file" && \
        awk "/$head/{ skip=1;print } /$tail/{ skip=0; system(\"cat $src\") } !skip{ print }" \
        > "$file"; } < "$file"
    else
        echo "$head" >> "$file"
        cat "$src" >> "$file"
        echo "$tail" >> "$file"
    fi


}

if [ "$TESTMODE" = "on" ]; then
    return
fi

main

