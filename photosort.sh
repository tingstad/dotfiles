#!/bin/bash

# Script to prepare photos for Facebook or similar,
# by Richard H. Tingstad (richard.tingstad+fb@gmail.com)
# version 2.6
#
# Makes target directory if needed
# Copies (and resizes) all jp(e)g files there,
# giving copied files names like YYYY-MM-DD_HH.MM.SS-C.jpg
# Renames copied images to date taken (and removes metadata)
# (Renames all copied files to 00000.jpg,00001.jpg,...)

usage(){
 echo "Sorts photos according to date taken by copying and renaming them,"
 echo "optionally resizing and anonomizing them."
 echo "By Richard H. Tingstad"
 echo ""
 echo "Usage: $0 [OPTIONS] source_dir_1...[source_dir_N] target_dir"
 echo ""
 echo "Options:"
 echo " --resize=PIXELS  Resize images to maximum PIXELS width/height. Will also"
 echo "                  strip images of metadata and auto-rotate them. If not set,"
 echo "                  the image files are simply copied."
 echo " --rename         Raname target files from YYYY-MM-DD_HH.MM.SS.jpg to NNNN.jpg."
 exit 1
}
if [ $# -lt 2 ]; then
 usage
fi
offset=1
for arg; do
 if [ "$arg" = "--rename" ]; then
  rename=true
  offset=$[ $offset + 1 ]
 elif [ "${arg:0:9}" = "--resize=" ]; then
  px=${arg#*=}
  offset=$[ $offset + 1 ]
  if ! echo "$px"|egrep -q '^[0-9]+$'; then
   echo "Invalid resize value: $px"
   exit 1
  fi
 fi
done
if [ $# -lt $[ $offset + 1 ] ]; then
 usage
fi

i=$offset
for src in "${@:$offset}"; do
 if [ $i -ge $# ]; then break; fi
 if [ ! -d "$src" ]; then
  echo "Not a directory: '$src'" >&2
  exit 1
 fi
 echo "Source: $src"
 i=$[ $i + 1 ]
done
for dir; do true; done
if echo "$dir" | egrep -q '/$'; then
 dir=`echo "$dir" | sed 's/\/$//'`
fi
echo "Target: $dir"
if [ ! -d "$dir" ]; then
 echo "Creating directory '$dir'..."
 if ! mkdir "$dir"; then
  echo "Could not create directory '$dir'" >&2
  exit 1
 fi
elif ls "$dir"/*.jpg >/dev/null 2>/dev/null; then
 echo "Warning: Existing jpg files in target directory! (May be renamed.)"
 sleep 3
fi

j=$offset
for src in "${@:$offset}";do
 if [ $j -ge $# ]; then
  break
 fi
 j=$[ $j + 1 ]
 find "$src" -maxdepth 1 -path "$dir" -prune -o -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) -print0 | while read -d $'\0' i
 do
  y=`stat --printf "%z\n%y\n%w" "$i" | sort | head -n 1` # smallest changed/modified/birth
  t=`identify -format "%[EXIF:*]" "$i" | egrep -i 'Exif:DateTime'|sort|head -n 1`
  t=`echo -e "$y\n$t" | sed 's/[^0-9]//g' | egrep -o '^[0-9]{0,14}' | sort | head -n 1`
  if [ ${#t} -lt 14 ]; then
   t=`printf "$t%0$[ 14 - ${#t} ]u" 0`
  fi
  t=`echo $t | sed -r 's/([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3_\4.\5.\6/'`
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

if [ ! $rename ];then
 exit 0
fi

#Anonymize file names.
c=0
find "$dir" -maxdepth 1 -type f -name '*.jpg' -print0 | sort -z | while read -d $'\0' i
do
 dest="$dir/`printf "%05u" "$c"`.jpg"
 echo "$i > $dest"
 mv "$i" "$dest"
 c=$[ $c + 1 ]
done
