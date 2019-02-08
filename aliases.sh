
alias gs='git status'
alias mci='mvn clean install'

grip(){
    find "${3-.}" -name '.[^.]*' -prune -o -name "${2:-*}" -type f -print0 | xargs -0 egrep --binary-files=without-match ${@:4} "$1" ;}

if ! docker version 2>/dev/null >/dev/null ;then
    echo "No docker found" >&2
    return
fi

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
        docker run --rm -v $infile:/input.dot:ro tsub/graph-easy "${args[@]}"
    else
        docker run --rm -i tsub/graph-easy "$@"
    fi
}

