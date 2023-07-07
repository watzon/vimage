module main

import color

fn main () {
	outer: for r := u8(0); r < 256; r += 7 {
		for g := u8(0); g < 256; g += 5 {
			for b := u8(0); b < 256; b += 3 {
				y, cb, cr := color.rgb_to_ycbcr(r, g, b)
				println('rgb_to_ycbr($r, $g, $b) = ($y, $cb, $cr)')
				r1, g1, b1 := color.ycbcr_to_rgb(y, cb, cr)
				println('ycbcr_to_rgb($y, $cb, $cr) = ($r1, $g1, $b1)')
				if b > 20 { break outer }
			}
		}
	}
}
