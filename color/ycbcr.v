module color

// rgb_to_ycbcr converts an RGB triple to a Y'CbCr triple.
pub fn rgb_to_ycbcr(r u8, g u8, b u8) (u8, u8, u8) {
	// The JFIF specification says:
	//	Y' =  0.2990*R + 0.5870*G + 0.1140*B
	//	Cb = -0.1687*R - 0.3313*G + 0.5000*B + 128
	//	Cr =  0.5000*R - 0.4187*G - 0.0813*B + 128
	// https://www.w3.org/Graphics/JPEG/jfif3.pdf says Y but means Y'.

	r1 := i32(r)
	g1 := i32(g)
	b1 := i32(b)

	// yy is in range 0..0xff
	yy := (19595 * r1 + 38470 * g1 + 7471 * b1 + 1 << 15) >> 16

	// The bit twiddling below is equivalent to
	//
	// cb := (-11056*r1 - 21712*g1 + 32768*b1 + 257<<15) >> 16
	// if cb < 0 {
	//     cb = 0
	// } else if cb > 0xff {
	//     cb = ~int32(0)
	// }
	//
	// but uses fewer branches and is faster.
	// Note that the u8 type conversion in the return
	// statement will convert ^int32(0) to 0xff.
	// The code below to compute cr uses a similar pattern.
	//
	// Note that -11056 - 21712 + 32768 equals 0.
	mut cb := -11056 * r1 - 21712 * g1 + 32768 * b1 + 257 << 15
	if u32(cb) & 0xff000000 == 0 {
		cb >>= 16
	} else {
		cb = ~(cb >> 31)
	}

	// Note that 32768 - 27440 - 5328 equals 0.
	mut cr := 32768 * r1 - 27440 * g1 - 5328 * b1 + 257 << 15
	if u32(cr) & 0xff000000 == 0 {
		cr >>= 16
	} else {
		cr = ~(cr >> 31)
	}

	return u8(yy), u8(cb), u8(cr)
}

// ycbcr_to_rgb converts a Y'CbCr triple to an RGB triple.
pub fn ycbcr_to_rgb(y u8, cb u8, cr u8) (u8, u8, u8) {
	// The JFIF specification says:
	//	R = Y' + 1.40200*(Cr-128)
	//	G = Y' - 0.34414*(Cb-128) - 0.71414*(Cr-128)
	//	B = Y' + 1.77200*(Cb-128)
	// https://www.w3.org/Graphics/JPEG/jfif3.pdf says Y but means Y'.
	//
	// Those formulae use non-integer multiplication factors. When computing,
	// integer math is generally faster than floating point math. We multiply
	// all of those factors by 1<<16 and round to the nearest integer:
	//	 91881 = roundToNearestInteger(1.40200 * 65536).
	//	 22554 = roundToNearestInteger(0.34414 * 65536).
	//	 46802 = roundToNearestInteger(0.71414 * 65536).
	//	116130 = roundToNearestInteger(1.77200 * 65536).
	//
	// Adding a rounding adjustment in the range [0, 1<<16-1] and then shifting
	// right by 16 gives us an integer math version of the original formulae.
	//	R = (65536*Y' +  91881 *(Cr-128)                  + adjustment) >> 16
	//	G = (65536*Y' -  22554 *(Cb-128) - 46802*(Cr-128) + adjustment) >> 16
	//	B = (65536*Y' + 116130 *(Cb-128)                  + adjustment) >> 16
	// A constant rounding adjustment of 1<<15, one half of 1<<16, would mean
	// round-to-nearest when dividing by 65536 (shifting right by 16).
	// Similarly, a constant rounding adjustment of 0 would mean round-down.
	//
	// Defining YY1 = 65536*Y' + adjustment simplifies the formulae and
	// requires fewer CPU operations:
	//	R = (YY1 +  91881 *(Cr-128)                 ) >> 16
	//	G = (YY1 -  22554 *(Cb-128) - 46802*(Cr-128)) >> 16
	//	B = (YY1 + 116130 *(Cb-128)                 ) >> 16
	//
	// The inputs (y, cb, cr) are 8 bit color, ranging in [0x00, 0xff]. In this
	// function, the output is also 8 bit color, but in the related YCbCr.RGBA
	// method, below, the output is 16 bit color, ranging in [0x0000, 0xffff].
	// Outputting 16 bit color simply requires changing the 16 to 8 in the "R =
	// etc >> 16" equation, and likewise for G and B.
	//
	// As mentioned above, a constant rounding adjustment of 1<<15 is a natural
	// choice, but there is an additional constraint: if c0 := YCbCr{Y: y, Cb:
	// 0x80, Cr: 0x80} and c1 := Gray{Y: y} then c0.RGBA() should equal
	// c1.RGBA(). Specifically, if y == 0 then "R = etc >> 8" should yield
	// 0x0000 and if y == 0xff then "R = etc >> 8" should yield 0xffff. If we
	// used a constant rounding adjustment of 1<<15, then it would yield 0x0080
	// and 0xff80 respectively.
	//
	// Note that when cb == 0x80 and cr == 0x80 then the formulae collapse to:
	//	R = YY1 >> n
	//	G = YY1 >> n
	//	B = YY1 >> n
	// where n is 16 for this function (8 bit color output) and 8 for the
	// YCbCr.RGBA method (16 bit color output).
	//
	// The solution is to make the rounding adjustment non-constant, and equal
	// to 257*Y', which ranges over [0, 1<<16-1] as Y' ranges over [0, 255].
	// YY1 is then defined as:
	//	YY1 = 65536*Y' + 257*Y'
	// or equivalently:
	//	YY1 = Y' * 0x10101

	yy1 := i32(y) * 0x10101
	cb1 := i32(cb) - 128
	cr1 := i32(cr) - 128

	// The bit twiddling below is equivalent to
	//
	// r := (yy1 + 91881*cr1) >> 16
	// if r < 0 {
	//     r = 0
	// } else if r > 0xff {
	//     r = ~int32(0)
	// }
	//
	// but uses fewer branches and is faster.
	// Note that the u8 type conversion in the return
	// statement will convert ^int32(0) to 0xff.
	// The code below to compute g and b uses a similar pattern.
	mut r := yy1 + 91881 * cr1
	if u32(r) & 0xff000000 == 0 {
		r >>= 16
	} else {
		r = ~(r >> 31)
	}

	mut g := yy1 - 22554 * cb1 - 46802 * cr1
	if u32(g) & 0xff000000 == 0 {
		g >>= 16
	} else {
		g = ~(g >> 31)
	}

	mut b := yy1 + 116130 * cb1
	if u32(b) & 0xff000000 == 0 {
		b >>= 16
	} else {
		b = ~(b >> 31)
	}

	return u8(r), u8(g), u8(b)
}

// YCbCr represents a fully opaque 24-bit Y'CbCr color, having 8 bits each for
// one luma and two chroma components.
//
// JPEG, VP8, the MPEG family and other codecs use this color model. Such
// codecs often use the terms YUV and Y'CbCr interchangeably, but strictly
// speaking, the term YUV applies only to analog video signals, and Y' (luma)
// is Y (luminance) after applying gamma correction.
//
// Conversion between RGB and Y'CbCr is lossy and there are multiple, slightly
// different formulae for converting between the two. This package follows
// the JFIF specification at https://www.w3.org/Graphics/JPEG/jfif3.pdf.
pub struct YCbCr {
	// Y is the luma component, specified as a number from 0 to 255.
	y u8
	// Cb and Cr are the blue-difference and red-difference chroma components,
	// specified as numbers from 0 to 255.
	cb u8
	cr u8
}

pub fn (c YCbCr) rgba() (u32, u32, u32, u32) {
	// This code is a copy of the YCbCrToRGB function above, except that it
	// returns values in the range [0, 0xffff] instead of [0, 0xff]. There is a
	// subtle difference between doing this and having YCbCr satisfy the Color
	// interface by first converting to an RGBA. The latter loses some
	// information by going to and from 8 bits per channel.

	yy1 := i32(c.y) * 0x10101
	cb1 := i32(c.cb) - 128
	cr1 := i32(c.cr) - 128

	// The bit twiddling below is equivalent to
	//
	// r := (yy1 + 91881*cr1) >> 8
	// if r < 0 {
	//     r = 0
	// } else if r > 0xff {
	//     r = 0xffff
	// }
	//
	// but uses fewer branches and is faster.
	// The code below to compute g and b uses a similar pattern.
	mut r := yy1 + 91881 * cr1
	if u32(r) & 0xff000000 == 0 {
		r >>= 8
	} else {
		r = ~(r >> 31) & 0xffff
	}

	mut g := yy1 - 22554 * cb1 - 46802 * cr1
	if u32(g) & 0xff000000 == 0 {
		g >>= 8
	} else {
		g = ~(g >> 31) & 0xffff
	}

	mut b := yy1 + 116130 * cb1
	if u32(b) & 0xff000000 == 0 {
		b >>= 8
	} else {
		b = ~(b >> 31) & 0xffff
	}

	return u32(r), u32(g), u32(b), 0xffff
}

pub fn make_ycbcr_model(c Color) Color {
	r, g, b, _ := c.rgba()
	y, u, v := rgb_to_ycbcr(u8(r >> 8), u8(g >> 8), u8(b >> 8))
	return YCbCr{y, u, v}
}

pub const ycbcr_model = ModelFunc{
	f: make_ycbcr_model
}

// NYCbCrA represents a non-alpha-premultiplied Y'CbCr-with-alpha color, having
// 8 bits each for one luma, two chroma and one alpha component.
pub struct NYCbCrA {
	// YCbCr is the luma, blue-difference and red-difference components.
	YCbCr // A is the alpha component, usually in the range 0-0xff.
	a u8
}

pub fn (c NYCbCrA) rgba() (u32, u32, u32, u32) {
	// The first part of this method is the same as YCbCr.RGBA.
	yy1 := i32(c.y) * 0x10101
	cb1 := i32(c.cb) - 128
	cr1 := i32(c.cr) - 128

	// The bit twiddling below is equivalent to
	//
	// r := (yy1 + 91881*cr1) >> 8
	// if r < 0 {
	//     r = 0
	// } else if r > 0xff {
	//     r = 0xffff
	// }
	//
	// but uses fewer branches and is faster.
	// The code below to compute g and b uses a similar pattern.
	mut r := yy1 + 91881 * cr1
	if u32(r) & 0xff000000 == 0 {
		r >>= 8
	} else {
		r = ~(r >> 31) & 0xffff
	}

	mut g := yy1 - 22554 * cb1 - 46802 * cr1
	if u32(g) & 0xff000000 == 0 {
		g >>= 8
	} else {
		g = ~(g >> 31) & 0xffff
	}

	mut b := yy1 + 116130 * cb1
	if u32(b) & 0xff000000 == 0 {
		b >>= 8
	} else {
		b = ~(b >> 31) & 0xffff
	}

	// The second part of this method applies the alpha.
	a := u32(c.a) * 0x101
	return u32(r) * a / 0xffff, u32(g) * a / 0xffff, u32(b) * a / 0xffff, a
}

pub fn make_nycbcr_model(c Color) Color {
	match c {
		NYCbCrA { return c }
		YCbCr { return NYCbCrA{c, 0xff} }
		else {}
	}

	mut r, mut g, mut b, a := c.rgba()

	// Convert from alpha-premultiplied to non-alpha-premultiplied.
	if a != 0 {
		r = r * 0xffff / a
		g = g * 0xffff / a
		b = b * 0xffff / a
	}

	y, u, v := rgb_to_ycbcr(u8(r >> 8), u8(g >> 8), u8(b >> 8))
	return NYCbCrA{
		y: y
		cb: u
		cr: v
		a: u8(a >> 8)
	}
}

pub const nycbcr_model = ModelFunc{
	f: make_nycbcr_model
}

// RGBToCMYK converts an RGB triple to a CMYK quadruple.
pub fn rgb_to_cmyk(r u8, g u8, b u8) (u8, u8, u8, u8) {
	rr := u32(r)
	gg := u32(g)
	bb := u32(b)
	mut w := rr
	if w < gg {
		w = gg
	}
	if w < bb {
		w = bb
	}
	if w == 0 {
		return 0, 0, 0, 0xff
	}
	c := (w - rr) * 0xff / w
	m := (w - gg) * 0xff / w
	y := (w - bb) * 0xff / w
	return u8(c), u8(m), u8(y), u8(0xff - w)
}

// CMYKToRGB converts a CMYK quadruple to an RGB triple.
pub fn cmyk_to_rgb(c u8, m u8, y u8, k u8) (u8, u8, u8) {
	// The formulae are:
	//	R = 255 - ((255-C) * (255-K)) / 255
	//	G = 255 - ((255-M) * (255-K)) / 255
	//	B = 255 - ((255-Y) * (255-K)) / 255
	// https://www.rapidtables.com/convert/color/cmyk-to-rgb.html

	w := 0xffff - u32(k) * 0x101
	r := (0xffff - u32(c) * 0x101) * w / 0xffff
	g := (0xffff - u32(m) * 0x101) * w / 0xffff
	b := (0xffff - u32(y) * 0x101) * w / 0xffff
	return u8(r >> 8), u8(g >> 8), u8(b >> 8)
}

// CMYK represents a fully opaque CMYK color, having 8 bits for each of cyan,
// magenta, yellow and black.
//
// It is not associated with any particular color profile.
pub struct CMYK {
	c u8
	m u8
	y u8
	k u8
}

pub fn (c CMYK) rgba() (u32, u32, u32, u32) {
	// This code is a copy of the CMYKToRGB function above, except that it
	// returns values in the range [0, 0xffff] instead of [0, 0xff].

	w := 0xffff - u32(c.k) * 0x101
	r := (0xffff - u32(c.c) * 0x101) * w / 0xffff
	g := (0xffff - u32(c.m) * 0x101) * w / 0xffff
	b := (0xffff - u32(c.y) * 0x101) * w / 0xffff
	return r, g, b, 0xffff
}

pub fn make_cmyk_model(c Color) Color {
	r, g, b, _ := c.rgba()
	c1, m, y, k := rgb_to_cmyk(u8(r >> 8), u8(g >> 8), u8(b >> 8))
	return CMYK{c1, m, y, k}
}

pub const cmyk_model = ModelFunc{
	f: make_cmyk_model
}
