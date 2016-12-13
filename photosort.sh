#!/bin/bash

# Script to prepare photos for Facebook or similar,
# by Richard H. Tingstad (richard.tingstad+fb@gmail.com)
# version 2.7
#
# Makes target directory if needed
# Copies (and resizes) all jp(e)g files there,
# giving copied files names like YYYY-MM-DD_HH.MM.SS-C.jpg
# Renames copied images to date taken (and removes metadata)
# (Renames all copied files to 00000.jpg,00001.jpg,...)

set -o errexit

usage() {
  cat << EOF
Sorts photos according to date taken by copying and renaming them,
optionally resizing and anonomizing them.
By Richard H. Tingstad

Usage: $0 [OPTIONS] source_dir_1...[source_dir_N] target_dir

Options:
 --resize=PIXELS  Resize images to maximum PIXELS width/height. Will also
                  strip images of metadata and auto-rotate them. If not set,
                  the image files are simply copied.
 --rename         Raname target files from YYYY-MM-DD_HH.MM.SS.jpg to NNNN.jpg.
 --recursive      Read source directories' subdirectories
EOF
  exit 1
}

fail() {
  echo "$1" >&2 && exit 1
}

check_dependencies() {
  for i in "identify -version" "convert -version" "stat --help" "find --help"
    do $i >/dev/null || fail "${i% *} failed and is a required command"
  done
}

[ $# -lt 2 ] && usage

offset=1
for arg; do
  offset=$[ $offset + 1 ]
  if [ "$arg" = "--rename" ]; then
    rename=true
  elif [ "$arg" = "--recursive" ]; then
    recursive=""
  elif [ "${arg:0:9}" = "--resize=" ]; then
    px=${arg#*=}
    echo "$px" | egrep -q '^[0-9]+$' || fail "Invalid resize value: $px"
  else
    offset=$[ $offset - 1 ]
  fi
done
[ $# -lt $[ $offset + 1 ] ] && usage

check_dependencies

i=$offset
for src in "${@:$offset}"; do
  [ $i -ge $# ] && break
  [ ! -d "$src" ] && fail "Not a directory: '$src'"
  echo "Source: $src"
  i=$[ $i + 1 ]
done
for dir; do true; done
echo "$dir" | egrep -q '/$' && dir="${dir%/*}"
echo "Target: $dir"
if [ ! -d "$dir" ]; then
  echo "Creating directory '$dir'..."
  mkdir "$dir"
elif [ $rename ] && ls "$dir"/*.jpg >/dev/null 2>/dev/null; then
  echo "Warning: Existing jpg files in target directory! (May be renamed.)"
  sleep 3
fi

j=$offset
for src in "${@:$offset}";do
  [ $j -ge $# ] && break
  j=$[ $j + 1 ]
  find "$src" ${recursive--maxdepth 1} -path "$dir" -prune -o \
    -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) -print0 \
  | while read -d $'\0' i ;do
    # smallest changed/modified/birth
    y=$(stat --printf "%z\n%y\n%w" "$i" | sort | head -n 1)
    t=$(identify -format "%[EXIF:*]" "$i" | grep -i 'Exif:DateTime' \
        | cut -d= -f2 | sort | head -n 1)
    t=$(echo -e "$y\n$t" | sed 's/[^0-9]//g' | egrep -o '^[0-9]{0,14}' \
        | sort | head -n 1)
    [ ${#t} -lt 14 ] && t=$(printf "$t%0$[ 14 - ${#t} ]u" 0)
    t=$(echo $t | sed -r \
's/([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3_\4.\5.\6/')
    FFORMAT="^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}.[0-9]{2}.[0-9]{2}(-[0-9]+)?$"
    echo "$t" | egrep -q "${FFORMAT}" || \
      fail "Unexpected error: $t does not have format ${FFORMAT}"
    y=$(basename "$i" .jpg)
    # Do not rename file to later date if it looks processed
    echo "$y" | egrep -q "${FFORMAT}" && \
      t=$(echo -e "$y\n$t" | sort | head -n 1)
    c=""
    while [ -e "$dir/$t$c.jpg" ]; do
      c=$[ $c - 1 ]
    done
    dest="$dir/$t$c.jpg"
    echo "$i > $dest"
    if [ -z "$px" ]; then
      cp "$i" "$dest"
    else
      convert -resize "$px"x$px\> -auto-orient -strip "$i" "$dest"
    fi
  done
done

[ $rename ] || exit 0

#Anonymize file names.
c=0
find "$dir" -maxdepth 1 -type f -name '*.jpg' -print0 | sort -z \
| while read -d $'\0' i ;do
  dest="$dir/$(printf "%05u" "$c").jpg"
  echo "$i > $dest"
  mv "$i" "$dest"
  c=$[ $c + 1 ]
done
