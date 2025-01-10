#!/bin/bash
set -o errexit

# inspired by https://github.com/jfrazelle/dotfiles

main() {
    local src_dir=$(cd "$(dirname "$0")"; pwd)
    link_dotfiles "$src_dir" "$HOME"
    add_aliases "$src_dir/aliases.sh" "$HOME/.bashrc"
    add_code "$HOME/.zshrc" "source \"$src_dir/zshrc\""
}

link_dotfiles() {
    local src_dir="$1"
    local target_dir="$2"
    find "$src_dir" -maxdepth 1 \
    \( -name '.*' -or -name gitignore \) \
    \( -type f -or -name .vim \) \
    -not -name '.*.swp' -not -name '.gitignore' -not -name .bashrc -not -name .travis.yml \
    -print \
    | while read f; do
        local fil="$target_dir/$(basename "$f")"
        if [ -e "$fil" -a ! -L "$fil" ]; then
            [ -f "$fil" ] && cp -L "$fil" "$fil.old" || mv "$fil" "$fil.old"
        fi
        ln -s -f "$f" "$fil"
    done
}

add_aliases() {
    local alias_file="$1"
    local target="$2"
    local content="source \"$alias_file\""
    add_code "$target" "$content"
}

add_code() {
    local target="$1"
    local tag="# TINGSTAD DOTFILES v2"
    local content="$2"
    # Handle v1:
    local head="#BEGIN TINGSTAD DOTFILES"
    local tail="#END TINGSTAD DOTFILES"
    if [ -f "$target" ] && grep -q "$head$" "$target"; then
        { rm "$target" && \
        sed "/^$head/,/^$tail/{ /^$tail/!d; /^$tail/s|.*|$content $tag|; }" \
        > "$target"; } < "$target"
    # Handle v2:
    elif [ -f "$target" ] && grep -q "$tag$" "$target"; then
        { rm "$target" && \
        sed "/$tag$/s|.*|$content $tag|" \
        > "$target"; } < "$target"
    elif [ -f "$target" ] && grep -q "TINGSTAD DOTFILES" "$target"; then
        echo "ERROR: Unknown TINGSTAD DOTFILES version!" >&2
        return 1
    else
        echo "$content $tag" >> "$target"
    fi
}

if [ "$TESTMODE" = "on" ]; then
    return
fi

main "$@"

