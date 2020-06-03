my_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"

alias gs='git status'
alias mci='mvn clean install'

grip(){
    find "${3-.}" -name '.[^.]*' -prune -o -name "${2:-*}" -type f -print0 | xargs -0 egrep --binary-files=without-match ${@:4} "$1" ;}

source "$my_dir"/docker_aliases.sh

if command -v tmux &>/dev/null `#tmux exists` \
   && [ -n "$PS1" ]            `#interactive` \
   && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]
then
  tmux new-session -t main
fi

check_updates_dotfiles() {
    local dir="$1"

    local file="$dir/$(date -I).lock"

    if [ -e "$file" ]; then
        local outdated="$(cat "$file")"
        if [ -n "$outdated" ]; then
            echo "$outdated"
        fi
        return
    fi
    find "$dir" -maxdepth 1 -name '*.lock' -delete

    local revision=$(git ls-remote origin master | cut -f1)
    if [ -n "$revision" ]; then
        if ! git merge-base --is-ancestor $revision master ;then
            echo "New dotfiles version available: $revision" > "$file"
        else
            touch "$file"
        fi
        check_updates_dotfiles "$dir"
    fi
}

check_updates_dotfiles "$my_dir"

