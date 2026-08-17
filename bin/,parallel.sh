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

declare -a border  # chunk starts in absolute byte offsets
border[0]=0

flag=
if echo test | dd bs=3 count=1 iflags=fullblock >/dev/null 2>&1; then
    flag="iflags=fullblock"
elif echo test | dd bs=3 count=1 iflag=fullblock >/dev/null 2>&1; then
    flag="iflag=fullblock"
fi

for (( i=1; i<procs; i++ )); do
    maxlinelen=65536
    # lseek to nominal chunk border, then probe for next newline
    linefix=$( (
        dd bs=1024k skip=$((i*len)) count=0 2>/dev/null
        dd bs=$maxlinelen $flag count=1 2>/dev/null
      ) < "$file" | head -n1 | wc -c | awk '{ print $1 }')
    [ $linefix -lt $maxlinelen ] || {
        echo >&2 "WARNING: newlines sparse, may affect line-oriented commands"
        linefix=0
    }
    border[$i]=$(( i * len * 1048576 + linefix ))
done

job() (
    i=$1; shift 1
    (
        [ $i -eq 0 ] || \
            dd bs=1 skip=${border[$i]} count=0 2>/dev/null

        if [ $((i+1)) -lt $procs ]; then
            s=$(( border[$((i+1))] - border[$i] ))
            q=$(( s / 1048576 ))
            r=$(( s % 1048576 ))

            [ $q -eq 0 ] || dd $flag bs=1024k count=$q 2>/dev/null
            [ $r -eq 0 ] || dd $flag bs=$r    count=1  2>/dev/null
        else
            cat
        fi
    ) < "$file" | "$@"
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

