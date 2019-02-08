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
    -not -name '.*.swp' -not -name '.gitignore' -not -name .bashrc \
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
    local head="#BEGIN TINGSTAD DOTFILES"
    local tail="#END TINGSTAD DOTFILES"
    if [ -f "$target" ] && grep -q "$head" "$target"; then
        { rm "$target" && \
        awk '/'"$head"'/{ skip=1; print }
            /'"$tail"'/{ skip=0; print "source \"'"$alias_file"'\"" }
            !skip{ print }' \
        > "$target"; } < "$target"
    else
        cat <<- EOF >> "$target"
			$head
			source "$alias_file"
			$tail
		EOF
    fi
}

if [ "$TESTMODE" = "on" ]; then
    return
fi

main "$@"

