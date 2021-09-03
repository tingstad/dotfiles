#!/bin/sh
# https://github.com/tingstad/dotfiles/
set -e

export LC_ALL=UTF-8 2>/dev/null

main() {
    text="$@"
    if [ -n "$text" ]; then
        shout "$text"
    else
        while IFS= read -r line; do
            shout "$line"
        done
    fi
}

shout() {
awk 'BEGIN {

init_a()

word="'"$1"'"
split(word, letters, "")

# Compose:
height = 32
for (k=1; k in letters; k++) {
    letter = toupper(letters[k])
    s = a[letter]

    char_len = split(s, chars, "")

    w = int( char_len / height )

    for (i=0; i < char_len; i++) {
        x = i % w
        y = int(i / w)
        spacing = (x == 0 ? "00" : "")
        canvas[y+1] = canvas[y+1] spacing chars[ y*w + x + 1 ]
    }
}
for (i=1; i <= height; i++) {
    all = all canvas[i]
}
len_chars = split(all, chars, "")

# Transform:
min = 1
w = int( len_chars / height )
for (y=5; y < height-5; y++) {
    for (x=0; x < w; x++) {
        x2 = x + (len_chars>2) * int(y*(1/2-x/w))
        y2 = y - int(5*sin(x*3.14/w))
        if (y2 < min) min = y2
        transformed[ y2 * w + x2 ] = chars[ y*w + x + 1 ]
    }
}
if (min < 1) {
# perhaps translate canvas pixels
}
all=""
for (c=1; c<=len_chars; c++)  all = all (transformed[c] ? transformed[c] : 0)

len_chars = split(all, chars, "")
w = int( len_chars / height )

# Render:
line = ""
for (y=3; y < height; y+=4) {
    for (x=1; x < w; x+=2) {
#     Braille pattern:
        p[1] = chars[ (y-3)*w + x-1 +1 ]
        p[2] = chars[ (y-2)*w + x-1 +1 ]
        p[3] = chars[ (y-1)*w + x-1 +1 ]
        p[7] = chars[ (y  )*w + x-1 +1 ]
        p[4] = chars[ (y-3)*w + x   +1 ]
        p[5] = chars[ (y-2)*w + x   +1 ]
        p[6] = chars[ (y-1)*w + x   +1 ]
        p[8] = chars[ (y  )*w + x   +1 ]

#     Unicode offset is 0x2800
#     We do not know if platform printf supports \u or \x
#     so we bet on printing UTF-8 muti-byte characters (octal).
#     0x2800-28FF are all within UTF-8 3 bytes range (0x800-0xFFFF)
#     and the 4 most significant bits are always 0010, resulting in
#     the 1st byte being: 1110 0010 = 226 = 0xE2 = 0342
#                         ^^^^-UTF-8 byte1/3 encoding prefix
#     the prefix of the next 2 bytes is 10, so we calculate
#     (after reversing the dot number order to get bits):

        for (j=1; j<=8; j++) b[j]=p[9-j]
        byte2 = 160 +  2*b[1] + b[2]
        byte3 = 128 + 32*b[3] + 16*b[4] + 8*b[5] + 4*b[6] + 2*b[7] + b[8]
        byte2_oct = sprintf("%o", byte2)
        byte3_oct = sprintf("%o", byte3)
        utf8 = "\\342\\" byte2_oct "\\" byte3_oct
        line = line utf8
    }
    line = line "\\n"
}
system("printf \"" line "\"")

}

function init_a() {

a["A"]="00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000011111000000'\
'00000011111000000'\
'00000111111100000'\
'00000111111100000'\
'00000111111100000'\
'00001111011100000'\
'00001111011110000'\
'00001110011110000'\
'00001110001110000'\
'00011110001111000'\
'00011100001111000'\
'00011110001111000'\
'00111111111111000'\
'00111111111111100'\
'00111110001111100'\
'01111000000011100'\
'01111000000011110'\
'01111000000011110'\
'11110000000011110'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000"

a["B"]="000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'001111111110000'\
'011111111111100'\
'011111111111100'\
'011110000111110'\
'011110000011110'\
'011110000011110'\
'011110000011100'\
'011110000111100'\
'011111111111000'\
'011111111111000'\
'011110111111100'\
'011110000011110'\
'011110000001111'\
'011110000001111'\
'011110000001110'\
'011110000011110'\
'011111111111110'\
'011111111111100'\
'001111111111000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000"

a["C"]="00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000011111100000'\
'00001111111111000'\
'00011111111111100'\
'00111110000111100'\
'00111100000011110'\
'01111100000001110'\
'01111000000001111'\
'01111000000000000'\
'01111000000000000'\
'01111000000000000'\
'01111000000000000'\
'01111000000000000'\
'01111000000000100'\
'01111000000001110'\
'00111100000011110'\
'00111110000111110'\
'00011111101111100'\
'00001111111111000'\
'00000111111110000'\
'00000000010000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000"

a["D"]="0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0011111111000000'\
'0111111111110000'\
'0111111111111100'\
'0111100001111100'\
'0111100000111110'\
'0111100000011110'\
'0111100000011111'\
'0111100000001110'\
'0111100000001111'\
'0111100000001111'\
'0111100000001111'\
'0111100000001111'\
'0111100000011110'\
'0111100000011110'\
'0111100000011110'\
'0111100001111100'\
'0111111111111100'\
'0111111111111000'\
'0011111111100000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000"

a["E"]="0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0011111111110'\
'0111111111111'\
'0111111111111'\
'0111110000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111111111110'\
'0111111111110'\
'0111111111110'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111111111111'\
'0111111111111'\
'0011111111111'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000"

a["F"]="0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0011111111111'\
'0111111111111'\
'0111111111111'\
'0111110000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111111111110'\
'0111111111110'\
'0111111111110'\
'0111110000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0011100000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000"

a["G"]="00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000011111100000'\
'00001111111111000'\
'00011111111111100'\
'00111110000111110'\
'00111100000011110'\
'01111000000001110'\
'01111000000000010'\
'01111000000000000'\
'01111000000000000'\
'01111000001111111'\
'01111000011111111'\
'01110000011111111'\
'01111000000001110'\
'01111000000001111'\
'00111100000011110'\
'00111110000011110'\
'00011111111111100'\
'00001111111111000'\
'00000111111110000'\
'00000000100000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000"

a["H"]="00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00111000000001110'\
'01111000000011110'\
'01111000000011110'\
'01111000000011110'\
'01111000000011110'\
'01111000000011110'\
'01111000000011110'\
'01111000000011110'\
'01111111111111110'\
'01111111111111110'\
'01111111111111110'\
'01111000000011110'\
'01111000000011110'\
'01111000000011110'\
'01111000000011110'\
'01111000000011110'\
'01111000000011110'\
'01111000000011110'\
'00111000000011110'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000"

a["I"]="000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'001110'\
'011110'\
'011110'\
'011110'\
'011110'\
'011110'\
'011110'\
'011110'\
'011110'\
'011110'\
'011110'\
'011110'\
'011110'\
'011110'\
'011110'\
'011110'\
'011110'\
'011110'\
'001110'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000"

a["J"]="0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000011110'\
'0000000011110'\
'0000000011110'\
'0000000011110'\
'0000000011110'\
'0000000011110'\
'0000000011110'\
'0000000011110'\
'0000000011110'\
'0000000011110'\
'0000000011110'\
'0000000011110'\
'0000000011110'\
'0110000011110'\
'1111000011110'\
'1111100011110'\
'0111111111100'\
'0011111111100'\
'0001111111000'\
'0000111000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000"

a["K"]="0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0011100000011110'\
'0111100000111100'\
'0111100001111000'\
'0111100001111000'\
'0111100011110000'\
'0111100111100000'\
'0111101111100000'\
'0111101111000000'\
'0111111110000000'\
'0111111111000000'\
'0111111111000000'\
'0111111111100000'\
'0111110111100000'\
'0111100011110000'\
'0111100011111000'\
'0111100001111100'\
'0111100000111100'\
'0111100000111100'\
'0011100000011111'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000"

a["L"]="0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0011100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111100000000'\
'0111111111110'\
'0111111111111'\
'0011111111111'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000"

a["M"]="00000000000000000000'\
'00000000000000000000'\
'00000000000000000000'\
'00000000000000000000'\
'00000000000000000000'\
'00000000000000000000'\
'00000000000000000000'\
'00111100000000011110'\
'01111100000000111110'\
'01111110000000111111'\
'01111110000000111111'\
'01111110000001111111'\
'01111111000001111111'\
'01111111000001111111'\
'01111111000011111111'\
'01111011100011101111'\
'01111011100011101111'\
'01111011100111011111'\
'01111011110111001111'\
'01111001110111001111'\
'01111001111110001111'\
'01111000111110001111'\
'01111000111110001111'\
'01111000111100001111'\
'01111000011100001111'\
'00111000011100001111'\
'00000000000000000000'\
'00000000000000000000'\
'00000000000000000000'\
'00000000000000000000'\
'00000000000000000000'\
'00000000000000000000"

a["N"]="00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00111000000001110'\
'00111100000001110'\
'01111100000001111'\
'01111110000001111'\
'01111111000001111'\
'01111111000001111'\
'01111111100001111'\
'01111011100001111'\
'01111011110001111'\
'01111001111001111'\
'01111000111001111'\
'01111000111111111'\
'01111000011111111'\
'01111000011111111'\
'01111000001111111'\
'01111000000111111'\
'01111000000111111'\
'01111000000011111'\
'00111000000011110'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000"

a["O"]="00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000011111100000'\
'00001111111111000'\
'00011111111111100'\
'00111110000111100'\
'00111100000111110'\
'01111000000011110'\
'01111000000001110'\
'01111000000001111'\
'01111000000001111'\
'01110000000001111'\
'01111000000001111'\
'01111000000001111'\
'01111000000011110'\
'01111000000011110'\
'00111100000011110'\
'00111100000111100'\
'00011111111111100'\
'00001111111111000'\
'00000111111110000'\
'00000001110000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000"

a["P"]="000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'001111111110000'\
'011111111111100'\
'011111111111100'\
'011110000111110'\
'011110000011111'\
'011110000011111'\
'011110000001111'\
'011110000001111'\
'011110000011110'\
'011110000111110'\
'011111111111100'\
'011111111111100'\
'011111111110000'\
'011110000000000'\
'011110000000000'\
'011110000000000'\
'011110000000000'\
'011110000000000'\
'001110000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000"

a["Q"]="00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000011111100000'\
'00001111111111000'\
'00011111111111000'\
'00111110000111100'\
'00111100000111110'\
'01111000000011110'\
'01111000000001110'\
'01111000000001111'\
'01111000000001111'\
'01110000000001111'\
'01111000000001111'\
'01111000000001111'\
'01111000000011110'\
'01111000011111110'\
'00111100011111110'\
'00111100001111110'\
'00011111111111100'\
'00001111111111000'\
'00000111111111100'\
'00000000010011100'\
'00000000000011100'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000'\
'00000000000000000"

a["R"]="000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'001111110110000'\
'011111111111100'\
'011111111111100'\
'011110000111110'\
'011110000011110'\
'011110000001110'\
'011110000011110'\
'011110000011110'\
'011110000011110'\
'011111111111100'\
'011111111111000'\
'011111111110000'\
'011110001111000'\
'011110001111000'\
'011110000111100'\
'011110000111100'\
'011110000111110'\
'011110000011110'\
'001110000011110'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000"

a["S"]="000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000011111110000'\
'000111111111000'\
'001111111111110'\
'001111000011110'\
'011110000011110'\
'011110000001110'\
'011111000000000'\
'001111110000000'\
'001111111100000'\
'000111111111000'\
'000001111111110'\
'000000001111110'\
'000000000011110'\
'001000000001111'\
'011110000001111'\
'011110000011110'\
'011111101111110'\
'001111111111100'\
'000011111111000'\
'000000010000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000"

a["T"]="00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'01111111111111'\
'11111111111111'\
'11111111111111'\
'01000111100100'\
'00000111100000'\
'00000111100000'\
'00000111100000'\
'00000111100000'\
'00000111100000'\
'00000111100000'\
'00000111100000'\
'00000111100000'\
'00000111100000'\
'00000111100000'\
'00000111100000'\
'00000111100000'\
'00000111100000'\
'00000111100000'\
'00000111100000'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000"

a["U"]="0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0011100000001110'\
'0111100000001111'\
'0111100000001111'\
'0111100000001111'\
'0111100000001111'\
'0111100000001111'\
'0111100000001111'\
'0111100000001111'\
'0111100000001111'\
'0111100000001111'\
'0111100000001111'\
'0111100000001111'\
'0111100000001111'\
'0111100000001110'\
'0011100000011110'\
'0011110000111110'\
'0011111111111100'\
'0001111111111000'\
'0000011111111000'\
'0000000100000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000"

a["V"]="0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0111000000001111'\
'1111100000001110'\
'0111100000011110'\
'0111100000011110'\
'0111100000011100'\
'0011110000111100'\
'0011110000111100'\
'0011110000111100'\
'0001110000111000'\
'0001111001111000'\
'0000111001111000'\
'0001111001110000'\
'0000111101110000'\
'0000111011110000'\
'0000111111100000'\
'0000011111100000'\
'0000011111100000'\
'0000011111100000'\
'0000001111000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000"

a["W"]="00000000000000000000000'\
'00000000000000000000000'\
'00000000000000000000000'\
'00000000000000000000000'\
'00000000000000000000000'\
'00000000000000000000000'\
'00000000000000000000000'\
'01110000001110000001110'\
'01110000001111000001110'\
'01111000011111000011110'\
'01111000011111000011110'\
'01111000011111000011110'\
'00111000011111000011100'\
'00111100111011100011100'\
'00111000111011100011100'\
'00111100111011100111100'\
'00011100111011100111100'\
'00011101110001100111000'\
'00011101110001110111000'\
'00011101110001111111000'\
'00011111100001111111000'\
'00001111110000111110000'\
'00001111100000111110000'\
'00001111100000111110000'\
'00001111100000111110000'\
'00000111000000011100000'\
'00000000000000000000000'\
'00000000000000000000000'\
'00000000000000000000000'\
'00000000000000000000000'\
'00000000000000000000000'\
'00000000000000000000000"

a["X"]="0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0111100000001110'\
'0111100000011110'\
'0011110000111100'\
'0011111000111100'\
'0001111000111000'\
'0000111001111000'\
'0000111111110000'\
'0000011111100000'\
'0000011111100000'\
'0000001111000000'\
'0000011111100000'\
'0000111111100000'\
'0000111111110000'\
'0000111011110000'\
'0001111001111000'\
'0011110000111100'\
'0011110000111100'\
'0111100000011110'\
'0111100000011110'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000"

a["Y"]="0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0111000000001111'\
'0111100000011110'\
'0111100000011100'\
'0011110000111100'\
'0011110000111100'\
'0001111001111000'\
'0001111001110000'\
'0000111111110000'\
'0000111111110000'\
'0000011111100000'\
'0000011111000000'\
'0000001111000000'\
'0000001111000000'\
'0000001111000000'\
'0000001111000000'\
'0000001111000000'\
'0000001111000000'\
'0000001111000000'\
'0000001111000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000'\
'0000000000000000"

a["Z"]="000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'011111111111110'\
'011111111111110'\
'011111111111111'\
'000000000111110'\
'000000000111100'\
'000000001111000'\
'000000001111000'\
'000000011110000'\
'000000111100000'\
'000000111100000'\
'000001111000000'\
'000011110000000'\
'000011110000000'\
'000111100000000'\
'001111100000000'\
'001111000000000'\
'011111111111110'\
'011111111111111'\
'011111111111111'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000"

a["0"]="000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000001111110000'\
'000011111111000'\
'000111111111100'\
'001111000111110'\
'001111000011110'\
'011110000011110'\
'011110000001110'\
'011110000001111'\
'011110000001111'\
'011110000001111'\
'011100000001111'\
'011110000001111'\
'011110000001111'\
'011110000001110'\
'001110000011110'\
'001111000011110'\
'001111111111100'\
'000111111111000'\
'000001111110000'\
'000000010000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000"
a["1"]="00000000000'\
'00000000000'\
'00000000000'\
'00000000000'\
'00000000000'\
'00000000000'\
'00000000000'\
'00000111100'\
'00011111100'\
'00111111100'\
'01111111100'\
'01110111100'\
'01100111100'\
'00000111100'\
'00000111100'\
'00000111100'\
'00000111100'\
'00000111100'\
'00000111100'\
'00000111100'\
'00000111100'\
'00000111100'\
'00000111100'\
'00000111100'\
'00000111100'\
'00000111100'\
'00000000000'\
'00000000000'\
'00000000000'\
'00000000000'\
'00000000000'\
'00000000000"
a["2"]="00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'00001111111000'\
'00011111111100'\
'00111111111110'\
'01111000011110'\
'01111000001111'\
'01110000001111'\
'00000000011110'\
'00000000011110'\
'00000000011100'\
'00000000111100'\
'00000001111000'\
'00000011110000'\
'00000111100000'\
'00001111100000'\
'00011110000000'\
'00111100000000'\
'01111111111111'\
'01111111111111'\
'01111111111111'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000'\
'00000000000000"
a["3"]="000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000011111110000'\
'000111111111100'\
'001111111111100'\
'001111000011110'\
'011110000011110'\
'000100000011110'\
'000000000011110'\
'000000000111100'\
'000000111111000'\
'000001111111000'\
'000000111111100'\
'000000000011110'\
'000000000011111'\
'000100000001111'\
'011110000011110'\
'011110000011110'\
'001111101111110'\
'001111111111100'\
'000011111111000'\
'000000100000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000"
a["4"]="000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000011111000'\
'000000011111100'\
'000000111111100'\
'000001111111100'\
'000001110111100'\
'000011110111100'\
'000011100111100'\
'000111000111100'\
'000111000111100'\
'001110000111100'\
'001110000111100'\
'011110000111100'\
'011111111111111'\
'011111111111111'\
'011111111111111'\
'000000000111100'\
'000000000111100'\
'000000000111100'\
'000000000111100'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000"
a["5"]="000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000111111111100'\
'001111111111100'\
'001111111111110'\
'001111000000000'\
'001110000000000'\
'001110000000000'\
'001110000100000'\
'001111111111000'\
'001111111111100'\
'001111100111110'\
'001110000011111'\
'000000000001110'\
'000000000001111'\
'000100000001111'\
'011110000001110'\
'001111000011110'\
'001111101111110'\
'000111111111100'\
'000011111111000'\
'000000010000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000"
a["6"]="000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000001111110000'\
'000011111111100'\
'000111111111100'\
'001111000011110'\
'001111000001110'\
'011110000000000'\
'011110000100000'\
'011110111111000'\
'011101111111100'\
'011111100111110'\
'011111000011111'\
'011110000001111'\
'011110000001111'\
'011110000001111'\
'001110000001110'\
'001111000011110'\
'001111101111110'\
'000111111111100'\
'000001111111000'\
'000000010000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000"
a["7"]="0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0111111111111'\
'0111111111111'\
'1111111111111'\
'0000000001111'\
'0000000011110'\
'0000000011110'\
'0000000011100'\
'0000000111100'\
'0000000111000'\
'0000001111000'\
'0000001110000'\
'0000011110000'\
'0000011110000'\
'0000111100000'\
'0000111100000'\
'0000111000000'\
'0001111000000'\
'0001110000000'\
'0011110000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000'\
'0000000000000"
a["8"]="000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000011111110000'\
'000111111111100'\
'001111111111100'\
'011111000011110'\
'001110000011110'\
'001110000001110'\
'001111000011110'\
'001111000111100'\
'000011111111000'\
'000011111111000'\
'001111111111100'\
'001111000011110'\
'011110000001110'\
'011110000001111'\
'011110000001111'\
'011110000011110'\
'001111110111110'\
'001111111111100'\
'000011111111000'\
'000000010000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000"
a["9"]="000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000011111100000'\
'000111111111000'\
'001111111111100'\
'001111000111100'\
'011110000011110'\
'011110000001110'\
'011100000011110'\
'011110000011111'\
'011110000011111'\
'001111100111111'\
'001111111111111'\
'000111111101111'\
'000001100001111'\
'000000000001110'\
'001110000011110'\
'011110000011100'\
'001111111111100'\
'000111111111000'\
'000011111110000'\
'000000010000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000'\
'000000000000000"

a["!"]="0000000'\
'0000000'\
'0000000'\
'0000000'\
'0000000'\
'0000000'\
'0000000'\
'0011100'\
'0011110'\
'0011110'\
'0011110'\
'0011110'\
'0011110'\
'0011110'\
'0011110'\
'0011110'\
'0011110'\
'0011100'\
'0011100'\
'0011100'\
'0000000'\
'0000000'\
'0001100'\
'0011100'\
'0011110'\
'0011110'\
'0000000'\
'0000000'\
'0000000'\
'0000000'\
'0000000'\
'0000000"
a["-"]="0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000001000'\
'0111111110'\
'0111111110'\
'0011111110'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000'\
'0000000000"
a[","]="000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'001110'\
'011110'\
'011110'\
'001100'\
'011100'\
'011100'\
'011100'\
'000000'\
'000000"
a["."]="000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'001000'\
'011110'\
'011110'\
'001110'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000"
a[" "]="000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000'\
'000000"

}'
}

if [ -n "$BASH_VERSION" ]; then
    return 2>/dev/null || true
fi

main "$@"

# Images generated using ImageMagick:
# for i in {A..Z}; do
#   convert -background black -fill white -font SFNSDisplayCondensed-Semibold.otf -pointsize 144 label:$i $i.png
#   convert $i.png +repage -resize x32 -monochrome -depth 1 -type Bilevel +dither pgm:- | tr "\000\001" "01" > $i.pgm
#   c=$(wc -c $i.pgm | sed 's/[^0-9]//g'); fold -w $((c/32)) $i.pgm >> out
# done
# Print ascii characters:
# for i in {48..57} ; do k=$(printf "\x$(printf %x $i)") ; echo "$k" ; done
# "awkify:"
# for i in {0..9}; do w=$(awk 'NR==2{print $1}' $i.pgm); awk 'NR>3' $i.pgm | fold -w $w | sed -E "1s/(.*)/a\[\"$i\"\]\=\"\1'\\\/; 2,32{s/(.*)/'\1'\\\/;}; 32s/'.$/\"/" ; done

