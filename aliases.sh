my_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"

alias gs='git status'
alias mci='mvn clean install'

grip(){
    find "${3-.}" -name '.[^.]*' -prune -o -name "${2:-*}" -type f -print0 | xargs -0 egrep --binary-files=without-match ${@:4} "$1" ;}

source "$my_dir"/docker_aliases.sh

if [ "${BASH_VERSION%%.*}" -ge 5 ] \
|| { \
    [ "${BASH_VERSION%%.*}" -eq 4 ] \
    && [[ "${BASH_VERSION#${BASH_VERSION%%.*}.}" == [3-9]* ]]
}
then # 4.3 and later
    export HISTSIZE=-1
    export HISTFILESIZE=-1
else
    export HISTSIZE=
    export HISTFILESIZE=
fi

source /dev/stdin <<EOF
gitlog() {
    "$my_dir"/gitlog.sh "\$@"
}
EOF
export -f gitlog

# Somewhat weird form to support Bash 3:
source /dev/stdin <<<"$(source "$my_dir"/gitlog.sh && type ccut | sed '1d')"
export -f ccut

if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

if command -v tmux &>/dev/null `#tmux exists` \
   && [ -n "$PS1" ]            `#interactive` \
   && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]
then
  tmux new-session -t main
fi

