my_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"

export PATH="$PATH:$my_dir/bin"

alias gs='git status'
alias mci='mvn clean install'
alias ,touchbar='sudo pkill TouchBarServer'
alias ,touchbar2='sudo killall “ControlStrip”'

grip(){
    ,grip "$@"
}

calc() { awk "BEGIN{ print $* }" ;}

timeout() {
# inspired by https://www.oilshell.org/blog/2017/01/13.html
    limit=$1;
    shift;
    ( "$@" ) & sleep $limit;
    kill %%
}

inplace()(
    file="$1"
    shift
    temp=$(mktemp)
    "$@" < "$file" > "$temp" && mv "$temp" "$file"
)

retry()(
    # https://github.com/teodorlu/terminalen-motorsag/blob/master/bin/repeatedly-try
    while ! "$@"
    do
        echo WOOPS
        echo prøver igjen om 1 sek
        sleep 1
    done
)

drop() {
    awk -v drop=$1 '{ buffer[++j]=$0 } NR>drop{ print buffer[j-drop]; delete buffer[j-drop] }'
}

randomstr() {
    awk -v len="${1:-20}" 'BEGIN {
        srand('$RANDOM');
        while(len-- > 0) {
            n = int(rand() * 62);
            printf("%c", (n>35 ? n+61 : (n>9 ? n+55 : n+48) ) );
        };
        print "";
    }'
}

watchfiles() {
    if [ $# -lt 2 ]; then
        echo >&2 "Usage: %0 FILENAME_PATTERN COMMAND ARGS..."
        return 1
    fi
    tmp=$(mktemp)
    pattern="$1"
    shift
    while true; do
        if find . -name "$pattern" -newer "$tmp" | grep . ; then
            "$@"
            touch "$tmp"
        fi
        sleep 0.1
    done
}

export -f timeout inplace calc drop randomstr watchfiles retry

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
PS1="\A \[\$(exitcolor)\]\$(exittext)$(exe reset) \u@\h $(exe yellow)\w$(exe reset)\$(git branch 2>/dev/null|grep \*)${prompt_suffix}\\$ "
unset -f exe
unset prompt_suffix

source /dev/stdin <<EOF
gitlog() {
    "$my_dir"/bin/,gitlog "\$@"
}
EOF
export -f gitlog

export CARGO_NET_GIT_FETCH_WITH_CLI=true CLICOLOR=1

# Somewhat weird form to support Bash 3:
source /dev/stdin <<<"$(source "$my_dir"/bin/,gitlog && type ccut | sed '1d')"
export -f ccut

if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

if [ -z "$TESTMODE" ] \
   && command -v tmux &>/dev/null `#tmux exists` \
   && [ -n "$PS1" ]            `#interactive` \
   && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]
then
  tmux new-session -t main
fi

