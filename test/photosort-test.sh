#!/bin/bash

testTimeTakenOlympus() {
    # Exif is UTC
    #touch --date='2016-11-06 23:17:22.000000000 +0100' "$DIR/PB060125.JPG"
    time=$(time_taken "$DIR/PB060125.JPG")
    assertEquals '' '2016-11-06_22.17.22' "$time" 
}

testTimeTakenInstagramSamsungGalaxyS5() {
    # Exif is UTC +01:00
    file="$DIR/IMG_20161126_202505.jpg"
    #touch --date='2016-11-26 20:25:05.000000000 +0100' "$file"
    assertEquals '2016-11-26_20.25.05' "$(time_taken "$file")"
}

testTimeTakenInstagramSamsungGalaxyS5_summer() {
    # Exif is 07:40:07 UTC +02:00
    file="$DIR/IMG_20160809_074007.jpg"
    #touch --date='2016-08-09 07:40:06.000000000 +0200' "$file"
    assertEquals '2016-08-09_07.40.07' "$(time_taken "$file")"
}

testTimeTakenSamsungGalaxyS5() {
    # 2015-11-11 is winter time (UTC +01:00)
    # File is 06:45 UTC +01:00
    # Exif is 07:45 UTC +??
    time=$(time_taken $DIR/20151111_074536.jpg)
    assertEquals '' '2015-11-11_06.45.36' "$time"
}

testNoArguments() {
    out=$(main)
    status=$?
    assertEquals 'Output should contain "Usage"' \
        "Usage" "$(echo $out | grep -o Usage)"
    assertTrue 'No arguments should fail' "[ $status -gt 0 ]"
}

testInvalidResizeValue() {
    out=$(main --resize=X $(mktemp -d) out/ 2>&1)
    status=$?
    assertEquals 'Output should contain error' \
        "Invalid resize value: X" "$out"
    assertTrue 'Invalid value should fail' "[ $status -gt 0 ]"
}

DIR="$( dirname "$(pwd)/$0" )"
. "$DIR/../photosort.sh"
set +o errexit
. "$DIR/shunit2.sh"

