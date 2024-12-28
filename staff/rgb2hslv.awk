# Convert RGB to HSL or HSV, specify type as 4th argument
{
    r = $1 / 255; g = $2 / 255; b = $3 / 255; type = $4 # default to hsl
    cmax = r
    if (g > cmax) cmax = g
    if (b > cmax) cmax = b
    cmin = r
    if (g < cmin) cmin = g
    if (b < cmin) cmin = b
    delta = cmax - cmin

    lv = (type == "hsv") ? cmax : (cmax + cmin) / 2

    if (delta == 0) {
        s = 0
        h = 0
    } else {
        if (type == "hsv") {
            s = cmax == 0 ? 0 : delta / cmax
        } else {
            s = delta / (lv < 0.5 ? cmax + cmin : 2 - cmax - cmin)
        }
        if (cmax == r) {
            h = (g - b) / delta
        } else if (cmax == g) {
            h = 2 + (b - r) / delta
        } else {
            h = 4 + (r - g) / delta
        }
        h *= 60
        if (h < 0) h += 360
    }
    printf "%.1f %.1f %.1f", h, s * 100, lv * 100
}