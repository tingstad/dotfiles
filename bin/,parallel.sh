#!/bin/bash
# Richard H. Tingstad
set -e

if [ $# -lt 3 ]; then
    p=$(basename $0)
    cat <<-EOF
		parallel
		
		Usage: $p FILE JOBS COMMAND...
		
		Example:
		  $p  big.txt 8 wc | awk '{ n+=$1; w+=$2; b+=$3 } END{ print n,w,b }'
		
		Richard H. Tingstad
		EOF
    exit
fi

file="$1"; procs="$2"; shift 2

[ -e "$file" ] || {
    echo >&2 "Not found: $file"
    exit 1; }

[ "$procs" -gt 0 ] || {
    echo >&2 "Jobs must be >0 but was: $procs"
    exit 1; }

size=$(ls -lkng "$file" | awk '{print $4}')
megs=$(( size / 1024 / 1024 ))

len=$(( megs / procs ))

if [ $len -lt 1 ]; then
    echo >&2 "less than 1 M per job"
    "$@" < "$file"
    exit $?
fi

names=123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
declare -a ps
for (( i=0; i< $procs; i++ )); do
    ps[i]=${names:$i:1}
done

declare -a start byteoffs adjustment

for i in ${!ps[@]}; do
    offset=$(( i * len ))
    start[$i]=$offset
    [ $i -gt 0 ] || continue
    offset=$(( offset * 1048576 ))
    adjustment[$i]=$(dd if="$file" bs=1 skip=$offset \
      | head -n1 | wc -c | awk '{ print $1 }')
    byteoffs[$i]=$(( $offset + 0 ))
done
adjustment[0]=0
byteoffs[0]=0

job() (
    i=$1; shift 1

    [ $i -lt $((procs-1)) ] && count="count=$((len))" || count=""

    (
        dd if="$file" bs=1024k skip=${start[$i]} $count 2>/dev/null \
        | (
            dd bs=1 of=/dev/null count=${adjustment[$i]} 2>/dev/null
            cat
        )
        if [ $i -lt $((procs-1)) ]; then
            dd if="$file" bs=1 skip=${byteoffs[$((i+1))]} \
              count=${adjustment[$((i+1))]} 2>/dev/null
        fi
    ) | "$@"
)

declare -a pids

for i in ${!ps[@]}; do
    job $i "$@" &
    pids[$i]=$!
done

wait

# TODO
# auto-detect number of procs to use (when not specified)?
# option to abort all jobs when one fail?
# option to abort all jobs when one finishes?
# option to return exit status based on all/some/none of the jobs?

