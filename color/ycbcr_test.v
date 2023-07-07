module color

fn delta(x u8, y u8) u8 {
	if x >= y {
		return x - y
	}
	return y - x
}

fn assert_eq(c0 Color, c1 Color) ! {
	r0, g0, b0, a0 := c0.rgba()
	r1, g1, b1, a1 := c1.rgba()
	assert(r0 == r1)
	assert(g0 == g1)
	assert(b0 == b1)
	assert(a0 == a1)
}

fn test_ycbcr_roundtrip() {
	outer: for r := u8(0); r < 256; r += 7 {
		for g := u8(0); g < 256; g += 5 {
			for b := u8(0); b < 256; b += 3 {
				y, cb, cr := rgb_to_ycbcr(r, g, b)
				println('rgb_to_ycbr($r, $g, $b) = ($y, $cb, $cr)')
				r1, g1, b1 := ycbcr_to_rgb(y, cb, cr)
				println('ycbcr_to_rgb($y, $cb, $cr) = ($r1, $g1, $b1)')
				if b > 20 { assert false == true }
			}
		}
	}
}
