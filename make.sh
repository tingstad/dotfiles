#!/bin/bash
set -o errexit

# inspired by https://github.com/jfrazelle/dotfiles

main() {
    local src_dir=$(cd "$(dirname "$0")"; pwd)
    link_dotfiles "$src_dir" "$HOME"
    add_aliases "$src_dir/aliases.sh" "$HOME/.bashrc"
}

link_dotfiles() {
    local src_dir="$1"
    local target_dir="$2"
    find "$src_dir" -maxdepth 1 \
    \( -name '.*' -or -name gitignore \) \
    -type f \
    -not -name '.*.swp' -not -name '.gitignore' -not -name .bashrc -not -name .travis.yml \
    -print \
    | while read f; do
        local fil="$target_dir/$(basename "$f")"
        [ -e "$fil" -a ! -L "$fil" ] && cp -L "$fil" "$fil.old"
        ln -s -f "$f" "$fil"
    done
}

add_aliases() {
    local alias_file="$1"
    local target="$2"
    local tag="# TINGSTAD DOTFILES v2"
    local content="source \"$alias_file\" $tag"
    # Handle v1:
    local head="#BEGIN TINGSTAD DOTFILES"
    local tail="#END TINGSTAD DOTFILES"
    if [ -f "$target" ] && grep -q "$head$" "$target"; then
        { rm "$target" && \
        sed "/^$head/,/^$tail/{ /^$tail/!d; /^$tail/s|.*|$content|; }" \
        > "$target"; } < "$target"
    # Handle v2:
    elif [ -f "$target" ] && grep -q "$tag$" "$target"; then
        { rm "$target" && \
        sed "/$tag$/s|.*|$content|" \
        > "$target"; } < "$target"
    elif [ -f "$target" ] && grep -q "TINGSTAD DOTFILES" "$target"; then
        echo "ERROR: Unknown TINGSTAD DOTFILES version!" >&2
        return 1
    else
        echo "$content" >> "$target"
    fi
}

if [ "$TESTMODE" = "on" ]; then
    return
fi

main "$@"

