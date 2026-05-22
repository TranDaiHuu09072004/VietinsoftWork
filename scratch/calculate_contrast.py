def relative_luminance(color):
    rgb = []
    for c in (color[1:3], color[3:5], color[5:7]):
        val = int(c, 16) / 255.0
        if val <= 0.03928:
            rgb.append(val / 12.92)
        else:
            rgb.append(((val + 0.055) / 1.055) ** 2.4)
    return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]

def contrast_ratio(c1, c2):
    l1 = relative_luminance(c1)
    l2 = relative_luminance(c2)
    if l1 < l2:
        l1, l2 = l2, l1
    return (l1 + 0.055) / (l2 + 0.055)

bg = "#1e2329"
base_green = "#1d9336"

print(f"Base green {base_green} on {bg}: {contrast_ratio(base_green, bg):.2f}:1")

# Find a green color starting from #1d9336 and increasing brightness/saturation
# until contrast is >= 4.5:1 on #1e2329
import colorsys

r, g, b = int(base_green[1:3], 16), int(base_green[3:5], 16), int(base_green[5:7], 16)
h, s, v = colorsys.rgb_to_hsv(r/255.0, g/255.0, b/255.0)

best_color = None
for new_v in range(int(v*100), 101):
    for new_s in range(int(s*100), 101):
        nr, ng, nb = colorsys.hsv_to_rgb(h, new_s/100.0, new_v/100.0)
        hex_color = f"#{int(nr*255):02x}{int(ng*255):02x}{int(nb*255):02x}"
        cr = contrast_ratio(hex_color, bg)
        if cr >= 4.5:
            print(f"Candidate: {hex_color} (H={h*360:.1f}, S={new_s}%, V={new_v}%) -> Contrast: {cr:.2f}:1")
            best_color = hex_color
            break
    if best_color:
        break
