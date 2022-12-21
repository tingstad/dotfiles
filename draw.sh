#!/bin/sh
# https://github.com/tingstad/dotfiles/
set -e

export LC_ALL=UTF-8 2>/dev/null

main() {
    {
    t=180
    while [ $(( t += 1 )) -lt 360 ]; do
        echo $t
        sleep 0.1
    done } | draw "$@"
}

draw() {
awk -v str="$1" -v cols="$2" -v lines="$3" 'BEGIN {
    height = lines * 4
    if (height < 60) height = 60
    width = cols * 2
    if (width < 80) width = 80
    system("printf \"\\033[H\\033[J\"") # clear screen
    for (i = 0; i < 256; i++)
        oct[i] = sprintf("%o", i)
    h = height
    w = width
    size = height * w
    #startx = w / 2      + int( 20 * cosr)
    #starty = height - 1 - int( 20 * sinr)
    startx = int(w / 2)
    starty = h - 1
    for (i = 0; i < 180; i++) {
        rad = i * 3.14159 / 180
        sint[i] = sin(rad)
        cost[i] = cos(rad)
        opp[i] = int(w/2 * ( sint[i] / cost[i] ))
    }
    bottom = height - 1
    strlen = length(str)
    strwidth = strlen * 2
    strstart = startx - int(strlen / 2) * 2
}
{
  t = $0

  for (c = 0; c < size; c++)  canvas[c] = 0

  ang = t
  drawLines(ang)
    
    #for (x = 0; x < w; x++)
    #    for (y = h-1; y>h-20; y--)
    #        canvas[ y * w + x ] = 31

    n = strstart + strwidth
    y = starty - 4
    for (x = strstart - 1; x <= n; x++) {
        canvas[ y * w + x ] = 0
    }
    y--
    for (x = strstart; x < n; x++) {
        canvas[ y * w + x ] = 0
    }
    x = strstart - 1
    for (y = starty - 4; y < h; y++) {
        canvas[ y * w + x ] = 0
    }
    x = n - 1
    for (y = starty - 4; y < h; y++) {
        canvas[ y * w + x ] = 0
    }

  #for (x = 0; x < w; x++) {
  #    y = 8 + int(4 * sin((x-t) / 6 ) )
  #    canvas[ y * w + x ] = 2
  #  for (y = y+6; y>=0; y--)
  #    canvas[ y * w + x ] = 0
  #    y = 8 + int(4 * sin((x-t) / 6 ) )
  #    canvas[ y * w + x ] = 2
  #}

# Render:
line = "\\033[H" #cursor top left (= [1;1H )

for (y=3; y < height; y+=4) {
    for (x=1; x < w; x+=2) {
        if (y == starty && x-1 == strstart) {
          line = line str
          x += strwidth - 1
        }
#     Braille pattern:
        b[1] = canvas[ (y-3)*w + x-1 ]
        b[2] = canvas[ (y-2)*w + x-1 ]
        b[3] = canvas[ (y-1)*w + x-1 ]
        b[7] = canvas[ (y  )*w + x-1 ]
        b[4] = canvas[ (y-3)*w + x   ]
        b[5] = canvas[ (y-2)*w + x   ]
        b[6] = canvas[ (y-1)*w + x   ]
        b[8] = canvas[ (y  )*w + x   ]

#     Unicode offset is 0x2800
#     We do not know if platform printf supports \u or \x
#     so we bet on printing UTF-8 muti-byte characters (octal).
#     0x2800-28FF are all within UTF-8 3 bytes range (0x800-0xFFFF)
#     and the 4 most significant bits are always 0010, resulting in
#     the 1st byte being: 1110 0010 = 226 = 0xE2 = 0342
#                         ^^^^-UTF-8 byte1/3 encoding prefix
#     The prefix of the next 2 bytes is 10, so we calculate:

        if (!b[1] && !b[2] && !b[3] && !b[4] && !b[5] && !b[6] && !b[7] && !b[8]) {
          line = line " "    # blank pattern
          continue
        }
        byte2 = 160 +  2*!!b[8] + !!b[7]
        byte3 = 128 + 32*!!b[6] + 16*!!b[5] + 8*!!b[4] + 4*!!b[3] + 2*!!b[2] + !!b[1]
        #if (byte2 == 160 && byte3 == 128) {
        #  line = line " "    # blank pattern
        #  continue
        #}
        byte2_oct = oct[byte2]
        byte3_oct = oct[byte3]
        for (j = 1; j <= 8; j++)
            if (b[j]) {
                color = b[j]
                break
            }
        utf8 = "\\342\\" byte2_oct "\\" byte3_oct
        line = line "\\033[" color "m" utf8 "\\033[m"
    }
    line = line "\\n"
}
system("printf \"" line "\"")

}

function drawLines(ang) {
    c = 0
    for (j = ang; j >= 0 && c < 6; j -= 30)
        drawCone(j, (c++ % 2 == 0 ? 33 : 31))
}

function drawCone(ang, c) {
    color = c
    fillx = 0
    if ((ang - 10) % 180 > 90) {
        if (ang % 180 < 90) fillx = 1
        drawLine(ang)
        fillx = -1
        drawLine(ang - 10)
    } else {
        if (ang > 10)
            drawLine(ang - 10)
        fillx = 1
        drawLine(ang)
    }
}

function drawLine(angr) {
    ang = angr % 180
    if (ang == 90) {
        plotLine(startx, starty, startx, 0)
    } else if (ang < 90) {
        plotLine(startx, starty, w - 1, height - opp[ang])
    } else {
        plotLine(startx, starty, startx - opp[ang - 90], 0)
    }
}

function plotLine(x0, y0, x1, y1) {
    if (abs(y1 - y0) < abs(x1 - x0)) {
        if (x0 > x1)
            plotLineLow(x1, y1, x0, y0)
        else
            plotLineLow(x0, y0, x1, y1)
    } else {
        if (y0 > y1) {
            plotLineHigh(x1, y1, x0, y0)
        }
        else {
            #plotLineHigh(x0, y0, x1, y1)
        }
    }
}

function plotLineLow(x0, y0, x1, y1) {
    dx = x1 - x0
    dy = y1 - y0
    yi = 1
    if (dy < 0) {
        yi = -1
        dy = -dy
    }
    D = (2 * dy) - dx
    y = y0

    off = y * w
    for (x = x0; x <= x1; x++) {
        if (x >= w || y >= height || y < 0) break
        if (x >= 0)
            plot(off, x)
        if (D > 0) {
            y = y + yi
            off += w * yi
            D = D + (2 * (dy - dx))
        } else
            D = D + 2*dy
    }
}

function plotLineHigh(x0, y0, x1, y1) {
    dx = x1 - x0
    dy = y1 - y0
    xi = 1
    if (dx < 0) {
        xi = -1
        dx = -dx
    }
    D = (2 * dx) - dy
    x = x0

    off = y0 * w
    for (y = y0; y <= y1; y++) {
        if (x >= w || y >= height) break
        if (y >= 0 && x >= 0)
            plot(off, x)
        if (D > 0) {
            x = x + xi
            D = D + (2 * (dx - dy))
        } else
            D = D + 2*dx
        off += w
    }
}

function plot(off, x) {
    i = off + x
    if (canvas[i])
        return
    canvas[i] = color
    if (fillx) {
        max = off + w
        i += fillx
        while (i >= off && i < max && !canvas[i]) {
            canvas[i] = color
            i += fillx
        }
    }
}

function abs(n) {
    return n < 0 ? -n : n
}
'
}

if [ -n "$BASH_VERSION" ]; then
    return 2>/dev/null || true
fi

main "$@"

