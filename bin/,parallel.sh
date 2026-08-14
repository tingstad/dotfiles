#!/bin/bash
# Richard H. Tingstad
set -e

if [ $# -lt 3 ]; then
    p=$(basename $0)
    cat <<-EOF
		parallel
		
		Usage: $p FILE JOBS COMMAND...
		
		Example:
		  $p  big.txt 8 wc | awk '{ n+=\$1; w+=\$2; b+=\$3 } END{ print n,w,b }'
		
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
megs=$(( size / 1048576 )) # 1048576 = 1024 * 1024

len=$(( megs / procs ))

if [ $len -lt 1 ]; then
    echo >&2 "WARNING: less than 1M per job, not parallelizing"
    "$@" < "$file"
    exit $?
fi

names=123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0_,
declare -a ps
for (( i=0; i< $procs; i++ )); do
    ps[i]=${names:$i:1}
done

declare -a linefix  # bytes from chunk border to next newline
linefix[0]=0        # first chunk has no head to skip
linefix[$procs]=0   # last chunk has no tail to append

for (( i=1; i<procs; i++ )); do
    offset=$(( i * len * 1048576 ))  # chunk border
    linefix[$i]=$(dd if="$file" bs=1 skip=$offset count=2048 2>/dev/null \
      | head -n1 | wc -c | awk '{ print $1 }')
    [ ${linefix[$i]} -lt 2048 ] || {
        echo >&2 "WARNING: newlines sparse, may affect line-oriented commands"
        linefix[$i]=0
    }
done

job() (
    i=$1; shift 1

    [ $i -lt $((procs-1)) ] && count="count=$len" || count=""

    (
        dd if="$file" bs=1024k skip=$((i*len)) $count 2>/dev/null \
        | (
            [ ${linefix[$i]} -eq 0 ] || \
                dd bs=1 of=/dev/null count=${linefix[$i]} 2>/dev/null
            cat
        )
        if [ ${linefix[$((i+1))]} -gt 0 ]; then
            dd if="$file" bs=1 skip=$(( (i+1) * len * 1048576 )) \
              count=${linefix[$((i+1))]} 2>/dev/null
        fi
    ) | "$@"
)

atomiclines() {
    # Make sure concurrent writers to a shared pipe don't tear each other's
    # output, by passing stdin to stdout in small enough chunks (<= $1), and
    # redirecting long lines (> $1) to file ($2) for caller to handle
    # (synchronously) after writers are finished.
    # Whole lines are buffered until reaching limit ($1) and then flushed,
    # staying atomic against other writers on the same pipe:
    # POSIX guarantees write() to a pipe to be atomic for sizes <= PIPE_BUF
    # (>= 512).  Line order is not preserved.
    awk -v max="$1" -v file="$2" '{
        s = length($0) + 1
        if (s > max) {
            print $0 >> file
        } else if (n + s > max) {
            printf "%s", buf; fflush()
            buf = $0 "\n"
            n = s
        } else {
            buf = buf $0 "\n"
            n += s
        }
    }
    END {
        if (n) { printf "%s", buf; fflush() }
    }'
}

declare -a pids
pipebuf=$(getconf PIPE_BUF . 2>/dev/null || true)
tmp=${TMPDIR:-/tmp}
prefix=${tmp%/}/job_$$_
trap 'rm -f "$prefix"*' EXIT INT TERM

for i in ${!ps[@]}; do
    job $i "$@" | atomiclines ${pipebuf:-512} "$prefix$i" &
    pids[$i]=$!
done

wait

cat "$prefix"* 2>/dev/null || true

# TODO
# auto-detect number of procs to use (when not specified)?
# option to abort all jobs when one fail?
# option to abort all jobs when one finishes?
# option to return exit status based on all/some/none of the jobs?
#
# -p num  set number of procs
#
# -e      end on first error (fail fast)
# -m num  max completions, -m1 : "any"
#
# exit status:
# default: 0 if all jobs succeed (like xargs -P)
# -s  some success - 0 if at least one job succeeds
#

