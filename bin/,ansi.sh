#!/bin/sh
# POSIX Shell+awk+od(octal dump) ANSI codes interpreter
# by Richard H. Tingstad
set -e

main() {
    while getopts o:sw:h: opt; do
        case $opt in
            o)  case $OPTARG in
                    html|txt|ansi) output=$OPTARG ;;
                    *) echo >/dev/stderr \
                        "invalid -o $OPTARG, expected html|txt|ansi"
                        return 1 ;;
                esac ;;
            w) width=$OPTARG ;;
            h) height=$OPTARG ;;
            ?) usage; exit 1 ;;
        esac
    done
    shift $((OPTIND - 1))
    [ -n "$width" ] || width=$COLUMNS
    [ -n "$height" ] || height=$LINES
    [ -n "$width" ] && [ -n "$height" ] || read h w <<-EOF
		$(stty size 2>/dev/null)
		EOF
    [ -n "$width" ] || width=$w \
        && [ -n "$width" ] || width=$(tput cols 2>/dev/null) || true
    [ -n "$height" ] || height=$h \
        && [ -n "$height" ] || height=$(tput lines 2>/dev/null) || true

    hexdump="od -v -A n -t x1"

    $hexdump \
    | awk '/./ {
        # one per line (tr -s " " "\n" | grep . | tr "[:upper:]" "[:lower:]")
        for (i = 1; i <= NF; i++) print tolower($i) }' \
    | awk '
        /08/ { csi("44"); next } # BS -> ^[[D
        /0a/ { csi("45"); next } # LF -> ^[[E
        /0d/ { csi("47"); next } # CR -> ^[[G
        { print }
        function csi(code) {
            print "1b"; print "5b"; print code }' \
    | awk -v width=${width:-80} -v height=${height:-25} \
        -v output=${output:-html} '
    BEGIN {
        for (i = 0; i < 128; i++) {
            h = sprintf("%x", i)
            s = sprintf("%c", i)
            ascii[h] = s
            hex[s] = h
        }
        initcolor()
    }

    /[89a-f][0-9a-f]/ { # multi-byte character
        pre = data[c+1]
        if ($1 == "9b" && (pre == "c2" || !pre)) {
            # 0x9b (UTF-8 c2 9b) CSI is equivalent to ESC [
            delete data[c+1]
            multi = 0
            params = ""
            state = 2
            next
        }
        multi = 1
        data[c+1] = (pre (pre ? "\n" : "") $1)
        params = ""
        state = 0
        next
    }
    multi {
        multi = 0
        c++
    }

    state == 0 && /1b/ { state++; next } # ESC
    state == 1 && /5b/ { state++; next } # [
    state == 1 && /63/ { # c (reset)
        pre = code[c + 1]
        code[c + 1] = (pre (pre ? "," : "") "48,4a") # H,J
        style[c + 1] = "m"
        params = ""
        state = 0
        next
    }
    state == 2 && /3[0-9b]/ { # 0–9;
        params = (params (params ? " " : "") $1)
        next
    }
    state == 2 && /4[1-8ab]/ { # A-H,J,K
        params = (params (params ? " " : "") $1)
        pre = code[c + 1]
        code[c + 1] = (pre (pre ? "," : "") params)
        params = ""
        state = 0
        next
    }
    state == 2 && /6d/ { # m
        params = (params (params ? " " : "") $1)
        if (params == "6d") params = "30 6d" # m -> 0m
        pre = style[c + 1]
        if (pre) sub(/6d$/, "3b", pre) # m -> ;
        style[c + 1] = (pre (pre ? " " : "") params)
        params = ""
        state = 0
        next
    }
    state > 0 { data[++c] = "1b" } # ESC
    state > 1 { data[++c] = "5b" } # [
    {
        data[++c] = $1
        params = ""
        state = 0
    }

    END {
        if (multi || code[c+1]) c++

        x = 0
        y = 0

        #rendered = render(output)
        #rendition[y * width + x] = rendered

        for (i = 1; i <= c; i++) {
            if (code[i]) {
                res = execc(x, y, code[i])
                if (res) {
                    split(res, a, ",")
                    x = a[1]
                    y = a[2]
                }
            }
            if (style[i]) {
                sgr(style[i]) # sets vars; intensity, italics, underlined, ...
                rendered = render(output)
            }
            rendition[y * width + x] = rendered
            term[y * width + x] = data[i]
            if (data[i]) x++
        }

        max = 0
        for (i = 0; i < width * height; i++)
            if (term[i]) max = i

        if (output == "html")
            printhex("<pre style=\"background-color:black;\">")
        laststyle = ""
        for (y = 0; y < height; y++) {
            for (x = 0; x < width; x++) {
                i = y * width + x
                if (rendition[i] != laststyle) {
                    if (output == "html")
                        printhtml(laststyle, rendition[i])
                    else if (output == "ansi")
                        printansi(laststyle, rendition[i])
                    laststyle = rendition[i]
                }
                if (term[i])
                    print term[i]
                else
                    print "20" # space
            }
            if (i >= max) break
            print "0a" # newline
        }
        if (output == "html") {
            if (laststyle != "") printhex("</span>")
            printhex("\n</pre>")
        }
    }

    # Select Graphics Rendition
    function sgr(code) {

        s = ""
        n = split(code, a, " ")
        for (j = 1; j < n; j++)
            s = (s ascii[a[j]])

        # ECMA-48
        # ADDITIONAL CONTROL FUNCTIONS FOR CHARACTER-IMAGING I/O DEVICES (1979)

        n = split(s, a, ";")
        if (n == 0) { n = 1; a[1] = "0"; }

        for (j = 1; j <= n; j++) {
            op = a[j]
            if (op == 0) { # default
                intensity = 0
                italics = 0
                underlined = 0
                fg = 0
                bg = 0
                blinking = 0
                crossedout = 0
            } else if (op == 1) { # bold
                intensity = 1
            } else if (op == 2) { # faint
                intensity = 2
            } else if (op == 3) { # italics
                italics = 1
            } else if (op == 4) { # underlined
                underlined = 1
            } else if (op == 5 || op == 6) { # slowly/rapidly blinking
                blinking = op                # (lt or gte than 150 per minute)
            # 7 negative image
            # 8 concealed data
            } else if (op == 9) { # crossed out
                crossedout = 1
            # 10 default font
            # 11-19 alternative fonts
            # 20 fraktur
            } else if (op == 21) { # double underlined
                underlined = 2
            } else if (op == 22) { # normal intensity
                intensity = 0
            } else if (op == 23) { # not italics
                italics = 0
            } else if (op == 24) { # not underlined
                underlined = 0
            } else if (op == 25) { # not blinking
                blinking = 0
            # 27 not negative image
            # 28 not concealed
            } else if (op == 29) { # not crossed out
                crossedout = 0
            } else if (30 <= op && op <= 37 || 90 <= op && op <= 97) {
                fg = op
            } else if (op == 38 && n >= j+4 && a[j+1] == 2) {
                # 24 bit "true color": 38;2;r;g;b
                fg = a[++j] ";" a[++j] ";" a[++j] ";" a[++j]
            } else if (op == 38 && n >= j+2 && a[j+1] == 5) {
                # 8 bit 256 colors (palette table)
                if (a[j+2] < 16) {
                    fg = (a[j+2] < 8 ? 30 : 90) + a[j+2]; j+=2
                } else
                    fg = a[++j] ";" a[++j]
            } else if (op == 39) { # default color
                fg = 0
            } else if (40 <= op && op <= 47 || 100 <= op && op <= 108) {
                bg = op
            } else if (op == 48 && n >= j+4 && a[j+1] == 2) {
                bg = a[++j] ";" a[++j] ";" a[++j] ";" a[++j]
            } else if (op == 48 && n >= j+2 && a[j+1] == 5) {
                if (a[j+2] < 16) {
                    bg = (a[j+2] < 8 ? 30 : 90) + a[j+2]; j+=2
                } else
                    bg = a[++j] ";" a[++j]
            } else if (op == 49) { # default background color
                bg = 0
            }
        }
    }

    function printhtml(laststyle, current) {
        if (laststyle != "") printhex("</span>")
        if (current)
            printhex("<span style=\"" current "\">")
    }

    function printansi(laststyle, current) {
        if (laststyle != "" && current == "")
            printhex("\033[m")
        if (current)
            printhex(current)
    }

    function render(output) {
        if (output == "html") {
            return renderhtml()
        } else if (output == "ansi") {
            return renderansi()
        }
    }

    function renderhtml() {
        s = ""
        if (!class) {
            if (intensity == 1)
                s = s "font-weight:bold;"
            else if (intensity == 2)
                s = s "font-weight:lighter;"
            if (italics)
                s = s "font-style:italic;"
            if (underlined == 1)
                s = s "text-decoration:underline;"
            else if (underlined > 1)
                s = s "text-decoration:underline double;"
            if (blinking)
                s = s "text-decoration:blink;"
            if (crossedout)
                s = s "text-decoration:line-through;"
            if (fg) {
                if (fg ~ "^2;") {
                    val = substr(fg, 3)
                    gsub(";", ",", val)
                    val = "rgb(" val ")"
                } else if (fg ~ "^5;")
                    val = "rgb(" rgb(substr(fg, 3)) ")"
                else
                    val = color[fg "m"]
                s = s "color:" val ";"
            }
            if (bg) {
                if (bg ~ "^2;") {
                    val = substr(bg, 3)
                    gsub(";", ",", val)
                    val = "rgb(" val ")"
                } else if (bg ~ "^5;")
                    val = "rgb(" rgb(substr(bg, 3)) ")"
                else
                    val = color[(bg-10) "m"]
                s = s "background-color:" val ";"
            }
        } else {
            if (intensity)
                s = s (length(s) ? " " : "") "intensity" intensity
            if (underlined)
                s = s (length(s) ? " " : "") "underlined" underlined
            if (fg)
                s = s (length(s) ? " " : "") "fg" fg
            if (bg)
                s = s (length(s) ? " " : "") "bg" bg
        }
        return s
    }

    function renderansi() {
        s = ""
        if (intensity)
            s = s "\033[" intensity "m"
        if (italics)
            s = s "\033[3m"
        if (underlined == 1)
            s = s "\033[4m"
        else if (underlined > 1)
            s = s "\033[21m"
        if (blinking)
            s = s "\033[" blinking "m"
        if (crossedout)
            s = s "\033[9m"
        if (fg)
            s = s "\033[" ((fg ~ "^[25];") ? "38;" : "") fg "m"
        if (bg)
            s = s "\033[" ((bg ~ "^[25];") ? "48;" : "") bg "m"

        if (s == "")
            s = "\033[m"

        return s
    }

    function initcolor() {

        # Cascading Style Sheets, level 1 W3C Recommendation 17 Dec 1996
        # "suggested list of keyword color names [...]
        # These 16 colors are taken from the Windows VGA palette"

        color["30m"] = "black"   #000000
        color["31m"] = "maroon"  #800000
        color["32m"] = "green"   #008000
        color["33m"] = "olive"   #808000
        color["34m"] = "navy"    #000080
        color["35m"] = "purple"  #800080 "magenta"
        color["36m"] = "teal"    #008080 "cyan"
        color["37m"] = "silver"  #c0c0c0
        color["90m"] = "gray"    #808080
        color["91m"] = "red"     #ff0000
        color["92m"] = "lime"    #00ff00
        color["93m"] = "yellow"  #ffff00
        color["94m"] = "blue"    #0000ff
        color["95m"] = "fuchsia" #ff00ff "magenta"
        color["96m"] = "aqua"    #00ffff "cyan"
        color["97m"] = "white"   #ffffff
    }

    function execc(x0, y0, code) {
        nn = split(code, ar, ",")
        if (nn == 1) {
            return exec(x0, y0, code)
        }
        x = x0
        y = y0
        for (jj = 1; jj <= nn; jj++) {
            res = exec(x, y, ar[jj])
            if (length(res)) {
                split(res, a, ",")
                x = a[1]
                y = a[2]
            }
        }
        return x "," y
    }

    function exec(x0, y0, code) {
        x = x0
        y = y0
        s = ""
        n = split(code, a, " ")
        for (j = 1; j <= n; j++)
            s = (s ascii[a[j]])
        n = length(s)
        op = substr(s, n)
        if (n > 1)
            n = substr(s, 1, n-1)
        else
            n = ""
        if (op == "A") { # Up
            n = (n ? n : 1)
            y = y0 - n
            if (y < 0) y = 0
        } else if (op == "B") { # Down
            n = (n ? n : 1)
            y = y0 + n
            if (y >= height) y = height-1
        } else if (op == "C") { # Forward
            n = (n ? n : 1)
            x = x0 + n
            if (x >= width) x = width-1
        } else if (op == "D") { # Back
            n = (n ? n : 1)
            x = x0 - n
            if (x < 0) x = 0
        } else if (op == "E") { # Next line
            x = 0
            n = (n ? n : 1)
            y = y0 + n
            if (y >= height) y = height-1
        } else if (op == "F") { # Previous line
            x = 0
            n = (n ? n : 1)
            y = y0 - n
            if (y < 0) y = 0
        } else if (op == "G") { # Column
            n = (n ? n : 0)
            x = n - 1
            if (x < 0) x = 0
            if (x >= width) x = width-1
        } else if (op == "H") { # Position
            x = 0
            y = 0
            if (match(n, /;[0-9]+/)) {
                x = substr(n, RSTART + 1) - 1
                if (x < 0) x = 0
                if (x >= width) x = width-1
            }
            if (length(n)) {
                p = index(n, ";")
                if (p > 1) y = substr(n, 1, p-1) - 1
                if (y < 0) y = 0
                if (y >= height) y = height-1
            }
        } else if (op == "J") { # Erase screen
            j1 = y * width + x
            j2 = width * height
            if (n == 1) {
                j2 = j1
                j1 = 0
            } else if (n > 1) {
                j1 = 0
            }
            for (j = j1; j < j2; j++) {
                delete term[j]
                delete rendition[j]
            }
        } else if (op == "K") { # Erase line
            j1 = x
            j2 = width
            if (n == 1) {
                j1 = 0
                j2 = x
            } else if (n == 2) {
                j1 = 0
                j2 = width
            }
            for (j = j1; j < j2; j++) {
                delete term[y * width + j]
                delete rendition[y * width + j]
            }
        }
        if (x == x0 && y == y0) return ""
        return x "," y
    }

    function rgb(x) {
        if (x > 231) { # grayscale
            x = (x - 232) * 10 + 8
            return x "," x "," x
        }

        r1 = int( (x - 16) / 36 )
        if ( r1 == 0 )
          r = 0
        else
          r = r1 * 40 + 55
        g1 = int( ( (x - 16) % 36 ) / 6)
        if ( g1 == 0 )
          g = 0
        else
          g = g1 * 40 + 55
        b1 = (x - 16) % 6
        if ( b1 == 0 )
          b = 0
        else
          b = b1 * 40 + 55
        return r "," g "," b
    }

    # TODO 
    # "𝔄𝔅ℭ𝔇𝔈𝔉𝔊ℌℑ𝔍𝔎𝔏𝔐𝔑𝔒𝔓𝔔ℜ𝔖𝔗𝔘𝔙𝔚𝔛𝔜ℨ"
    # "abcdefghijklmnopqrstuvwxyz{}`~"
    # "▒␉␌␍␊°±␤␋┘┐┌└┼⎺⎻─⎼⎽├┤┴┬│≤≥π£◆·"

    function toascii(hex) {
        s = ""
        n = split(hex, a, " ")
        for (j = 1; j <= n; j++)
            s = (s ascii[a[j]])
        return s
    }

    function tohex(s) {
        hexs = ""
        for (j = 1; j <= length(s); j++)
            hexs = hexs ((j == 1 ? "" : "\n") hex[substr(s, j, 1)])
        return hexs
    }

    function printhex(s) {
        print tohex(s)
    }

    ' \
    | while read hex; do
        printf \\$(printf %03o 0x$hex)
    done
}

usage() {
    cat <<-EOF
Converts ANSI codes to HTML (primarily).

Usage: $(basename "$0") [options]

Options:

    -o format   Output format; html(default)|txt|ansi
                
    -w          Set width
    -h          Set height

Richard H. Tingstad
EOF
}

assert() {
    test "$1" = "$2" || {
        printf 'Unexpected value; expected, actual:\n%s\n%s\n' "$2" "$1"
        printf %s "$2" | od -v -A n -t x1
        printf %s "$1" | od -v -A n -t x1
        return 1
    }
}

if [ "$1" = test ]; then

    pre='<pre style="background-color:black;">'

    assert "$(printf 'Test1' | main -w 20)" \
        "$(printf "$pre"'Test1               \n</pre>')"

    assert "$(printf 'Test2 \nHello' | main -w 20)" \
        "$(printf "$pre"'Test2               \nHello               \n</pre>')"

    assert "$(printf 'Test3 \033[999Gx' | main -w 20)" \
        "$(printf "$pre"'Test3              x\n</pre>')"

    assert "$(printf '\033[1mTest4' | main -w 5)" \
        "$(printf "$pre"'<span style="font-weight:bold;">Test4</span>\n</pre>')"

    assert "$(printf 'Test5\n\033[31mHello' | main -w 10)" \
        "$pre"'Test5     
<span style="color:maroon;">Hello</span>     
</pre>'

    assert "$(printf 'Test6 abcd\033[5D left' | main -w 20)" \
        "$(printf "$pre"'Test6 left          \n</pre>')"

    assert "$(printf '\033[38;2;3;2;1mTest7' | main -w 5)" \
        "$(printf "$pre"'<span style="color:rgb(3,2,1);">Test7</span>\n</pre>')"

    assert "$(printf 'Test8 \n \033[AeS' | main -w 10)" \
        "$(printf "$pre"'TeSt8     \n          \n</pre>')"

    assert "$(printf 'Test9 \n\033[At\n ' | main -w 10)" \
        "$(printf "$pre"'test9     \n          \n</pre>')"

    assert "$(printf '\033[38;5;6mTestA' | main -w 5)" \
        "$(printf "$pre"'<span style="color:teal;">TestA</span>\n</pre>')"
        # 16 + 36r + 6g + b

    assert "$(printf '\033[38;5;18mTestB' | main -w 5)" \
      "$(printf "$pre"'<span style="color:rgb(0,0,135);">TestB</span>\n</pre>')"
      # 16 + 36r + 6g + b [0, 95, 135, 175, 215, 255] => 16 + 0r + 0g + 2 = 18

    assert "$(printf '\033[38;5;233mTestC' | main -w 5)" \
     "$(printf "$pre"'<span style="color:rgb(18,18,18);">TestC</span>\n</pre>')"

    assert "$(printf '\033[91mTestD' | main -w5 -o txt)" \
        "TestD"

    assert "$(printf 'TestE å\033[Dx' | main -w 10)" \
        "$(printf "$pre"'TestE x   \n</pre>')"

    assert "$(printf 'TestF\n\033[31mØ\033[32m✆\n\033[33m📞' | main -w 8)" \
        "$pre"'TestF   
<span style="color:maroon;">Ø</span><span style="color:green;">✆</span>      
<span style="color:olive;">📞</span>       
</pre>'

    assert "$(printf 'TestF \2331mF' | main -w 7)" \
        "$(printf "$pre"'TestF <span style="font-weight:bold;">F</span>\n</pre>')"

    assert "$(printf '\033[2m\033[1mTestG\033[m ' | main -w6 -o ansi)" \
        "$(printf '\033[1mTestG\033[m ')"

    assert "$(printf 'TestH\033c' | main -w6 -o txt)" \
        "$(printf '      ')"

    exit $?
fi

main "$@"

