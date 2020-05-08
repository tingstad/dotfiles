my_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"

alias gs='git status'
alias mci='mvn clean install'

grip(){
    find "${3-.}" -name '.[^.]*' -prune -o -name "${2:-*}" -type f -print0 | xargs -0 egrep --binary-files=without-match ${@:4} "$1" ;}

source "$my_dir"/docker_aliases.sh

