
if ! docker version >/dev/null 2>&1 ;then
    echo "No docker found" >&2
    return
fi

user_string='$(id -u):$(id -g)'

vol_opt='$(selinuxenabled 2>/dev/null && echo :Z)'

source /dev/stdin <<EOF
# Only working dir supported
node8() {
    local tty=""
    if test -t 0; then
        tty="-t"
    fi
    docker run \$tty -i -a stdin -a stdout -a stderr --rm -v "\$PWD":/dir$vol_opt -w /dir node:8.15.0-alpine node "\$@"
}
EOF
export -f node8

# Only working dir supported
alias npm='docker run -it --rm -v "$PWD":/dir'$vol_opt' -w /dir -p 127.0.0.1:8080:8080/tcp node:8.15.0-alpine npm'

# Only working dir supported
alias python='docker run -it --rm -v "$PWD":/dir'$vol_opt' -w /dir frolvlad/alpine-python3 python3'

# Only working dir supported
# ~/.m2/settings.xml is your friend
source /dev/stdin <<EOF
# Only working dir supported
mvn_8() {
    if [ ! -d "\$HOME/.m2" ]; then
        mkdir "\$HOME/.m2"
    fi
    local vol_opt="\$(selinuxenabled 2>/dev/null && echo :Z)"
    echo docker run -it --rm -v "\$PWD":/dir\$vol_opt -u "$user_string" -v "\$HOME/.m2":/var/mvn/.m2\$vol_opt -w /dir maven:3.6.0-jdk-8-alpine mvn -Duser.home=/var/mvn -Dmaven.repo.local=/var/mvn/.m2/repository "\$@"
    docker run -it --rm -v "\$PWD":/dir\$vol_opt -u "$user_string" -v "\$HOME/.m2":/var/mvn/.m2\$vol_opt -w /dir maven:3.6.0-jdk-8-alpine mvn -Duser.home=/var/mvn -Dmaven.repo.local=/var/mvn/.m2/repository "\$@"
}
EOF
export -f mvn_8

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

# Only stdin/stdout supported
alias dot='docker run --rm --network none -i risaacson/graphviz@sha256:f111059ce08697cc1ead8d9770b9d4ce7faa7af70bfc371d1609146ae0ac1243 dot -Tsvg'

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

for cmd in compare composite convert identify magick mogrify montage stream ; do
    alias $cmd='docker run --rm --network none -u "'"$user_string"'" -v "$PWD":/dir'"$vol_opt"' -w /dir v4tech/imagemagick@sha256:959eb75b13efb41a8f37495784150574d66175adebd0c6c18216b482c574d109 '$cmd
done

if ! >/dev/null 2>&1 command -v npx; then
    # Only working dir supported
    source /dev/stdin <<-EOF
	npx() {
	    local tty=""
	    if test -t 0; then
	        tty="-t"
	    fi
	    docker run \$tty -i -a stdin -a stdout -a stderr --rm -v "\$PWD":/dir$vol_opt -w /dir node:14.7.0-alpine3.10 npx "\$@"
	}
	EOF
    export -f npx
fi

does_exist='>/dev/null 2>&1 command -v'

source /dev/stdin <<EOF
pretty_json() {
    local cmd=node
    if ! $does_exist "\$cmd"; then cmd=node8; fi
    "\$cmd" -e "$(cat "$my_dir"/pretty-json.js)" "\$@"
}
EOF
export -f pretty_json

unset user_string vol_opt

# Others? netcat, socat, vimcat, Gimp, browser, mplayer, Eclipse, etc.

