# Convert HSL or HSV to RGB, specify type as 4th argument
{
    h = $1; s = $2 / 100; lv = $3 / 100; type = $4 # default to hsl

    h /= 60
    if (type == "hsv") {
        c = lv * s
        m = lv - c
    } else { # hsl
        c = lv < 0.5 ? 2 * lv * s : 2 * (1 - lv) * s
        m = lv - c / 2
    }
    x0 = h % 2 - 1
    x = c * (1 - (x0 > 0 ? x0 : -x0))
    h = int(h)

    if (h == 0 || h == 6) {
        r = c
        g = x
        b = 0
    } else if (h == 1) {
        r = x
        g = c
        b = 0
    } else if (h == 2) {
        r = 0
        g = c
        b = x
    } else if (h == 3) {
        r = 0
        g = x
        b = c
    } else if (h == 4) {
        r = x
        g = 0
        b = c
    } else {
        r = c
        g = 0
        b = x
    }

    r = (r + m) * 255; g = (g + m) * 255; b = (b + m) * 255
    printf "%.0f %.0f %.0f", r, g, b
}