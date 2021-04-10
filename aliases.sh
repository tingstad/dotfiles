my_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"

alias gs='git status'
alias mci='mvn clean install'

grip(){
    find "${3-.}" -name '.[^.]*' -prune -o -name "${2:-*}" -type f -print0 | xargs -0 egrep --binary-files=without-match ${@:4} "$1" ;}

source "$my_dir"/docker_aliases.sh

prompt_suffix=''
if [ "${BASH_VERSION%%.*}" -ge 5 ] \
|| { \
    [ "${BASH_VERSION%%.*}" -eq 4 ] \
    && [[ "${BASH_VERSION#${BASH_VERSION%%.*}.}" == [3-9]* ]]
}
then # 4.3 and later
    export HISTSIZE=-1
    export HISTFILESIZE=-1
else
    prompt_suffix='\n' # Cursor is misplaced on long lines from history when colored PS1
    export HISTSIZE=
    export HISTFILESIZE=
fi

if tput setaf 1 >&/dev/null; then #colors
    exe(){
        # Poor man's hash map for Bash < 4
        _colors='reset=\033[0m black=\033[30m red=\033[31m green=\033[32m yellow=\033[33m blue=\033[34m magenta=\033[35m cyan=\033[36m white=\033[37m'
        _head="${_colors#*${1}=}"
        printf "\[${_head%% *}\]"
    }
    exitcolor(){
        local rc=$?
        if [ $rc -eq 0 ]; then
            printf "\033[32m" #green
        else
            printf "\033[31m" #red
        fi
        return $rc #for exittext
    }
else
    exe(){ return; }
    exitcolor(){ return $?; }
    prompt_suffix=''
fi
exittext(){
    [ $? -eq 0 ] && printf ":)" || printf ":("
}
PS1="\A \[\$(exitcolor)\]\$(exittext)$(exe reset) \u@\h $(exe yellow)\w$(exe reset)\$(git branch 2>/dev/null|grep \*)${prompt_suffix}>"
unset -f exe
unset prompt_suffix

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

