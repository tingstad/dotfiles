
alias gs='git status'
alias mci='mvn clean install'

grip(){
    find "${3-.}" -name '.[^.]*' -prune -o -name "${2:-*}" -type f -print0 | xargs -0 egrep --binary-files=without-match ${@:4} "$1" ;}

if ! docker version >/dev/null 2>&1 ;then
    echo "No docker found" >&2
    return
fi

user_string='$(id -u):$(id -g)'

vol_opt='$(selinuxenabled 2>/dev/null && echo :Z)'

# Only working dir supported
alias npm='docker run -it --rm -v "$PWD":/dir'$vol_opt' -w /dir -p 127.0.0.1:8080:8080/tcp node:8.15.0-alpine npm'

# Only working dir supported
alias python='docker run -it --rm -v "$PWD":/dir'$vol_opt' -w /dir frolvlad/alpine-python3 python3'

# Only working dir supported
# ~/.m2/settings.xml is your friend
alias mvn8='docker run -it --rm -v "$PWD":/dir'$vol_opt' -u "'"$user_string"'" -v "$HOME/.m2":/var/mvn/.m2'$vol_opt' -w /dir maven:3.6.0-jdk-8-alpine mvn -Duser.home=/var/mvn -Dmaven.repo.local=/var/mvn/.m2/repository'

# Only stdout output supported
graph-easy() {
    declare -a args
    local infile arg i
    for i in $(seq 1 $#); do
        arg="${@:$i:1}"
        if [[ "$arg" != "-"* ]] && [ -z "$infile" ] && [ -f "$arg" ]; then
            infile="$(cd "$(dirname "$arg")"; pwd -P)/$(basename "$arg")"
            arg="/input.dot"
        fi
        args[$i]="$arg"
    done
    if [ -n "$infile" ]; then
        local vol_opt="ro$(selinuxenabled 2>/dev/null && echo ,Z)"
        docker run --rm --network none -v "$infile":/input.dot:$vol_opt tsub/graph-easy "${args[@]}"
    else
        docker run --rm --network none -i tsub/graph-easy "$@"
    fi
}

# Only working dir supported
unrar() {
   #docker run --privileged=true
    local user_string="$(id -u):$(id -g)"
    local vol_opt="$(selinuxenabled 2>/dev/null && echo :Z)"
    if [ $# -eq 1 ]; then
        docker run --rm --network none -u "$user_string" -v "$(pwd)":/files$vol_opt maxcnunes/unrar:latest unrar e -r "$1"
    else
        docker run --rm --network none -u "$user_string" -v "$(pwd)":/files$vol_opt maxcnunes/unrar:latest unrar "$@"
    fi
}

# Only working dir supported
alias pdftk='docker run --rm --network none -u "'"$user_string"'" -v "$(pwd)":/files'$vol_opt' jottr/alpine-pdftk:latest'

unset user_string vol_opt

# Others? netcat, socat, imagemagick, graphviz, vimcat, Gimp, browser, mplayer, Eclipse, etc.

