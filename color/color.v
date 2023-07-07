module color

// Color can convert itself to alpha-premultiplied 16-bits per channel RGBA.
// The conversion may be lossy.
pub interface Color {
	// Returns the alpha-premultiplied red, green, blue and alpha values
	// for the color. Each value ranges within [0, 0xffff], but is represented
	// by a u32 so that multiplying by a blend factor up to 0xffff will not
	// overflow.
	//
	// An alpha-premultiplied color component c has been scaled by alpha (a),
	// so has valid values 0 <= c <= a.
	rgba() (u32, u32, u32, u32)
}

// RGBA represents a traditional 32-bit alpha-premultiplied color, having 8
// bits for each of red, green, blue and alpha.
//
// An alpha-premultiplied color component C has been scaled by alpha (A), so
// has valid values 0 <= C <= A.
pub struct RGBA {
	r u32
	g u32
	b u32
	a u32
}

pub fn (c RGBA) rgba() (u32, u32, u32, u32) {
	mut r := u32(c.r)
	r |= r << 8
	mut g := u32(c.g)
	g |= g << 8
	mut b := u32(c.b)
	b |= b << 8
	mut a := u32(c.a)
	a |= a << 8
	return r, g, b, a
}

// RGBA64 represents a 64-bit alpha-premultiplied color, having 16 bits for
// each of red, green, blue and alpha.
//
// An alpha-premultiplied color component C has been scaled by alpha (A), so
// has valid values 0 <= C <= A.
pub struct RGBA64 {
	r u32
	g u32
	b u32
	a u32
}

pub fn (c RGBA64) rgba() (u32, u32, u32, u32) {
	return c.r, c.g, c.b, c.a
}

// NRGBA represents a non-alpha-premultiplied 32-bit color.
pub struct NRGBA {
	r u8
	g u8
	b u8
	a u8
}

pub fn (c NRGBA) rgba() (u32, u32, u32, u32) {
	mut r := u32(c.r)
	r |= r << 8
	r *= u32(c.a)
	r /= 0xff
	mut g := u32(c.g)
	g |= g << 8
	g *= u32(c.a)
	g /= 0xff
	mut b := u32(c.b)
	b |= b << 8
	b *= u32(c.a)
	b /= 0xff
	return r, g, b, u32(c.a)
}

// NRGBA64 represents a non-alpha-premultiplied 64-bit color,
// having 16 bits for each of red, green, blue and alpha.
pub struct NRGBA64 {
	r u16
	g u16
	b u16
	a u16
}

pub fn (c NRGBA64) rgba() (u32, u32, u32, u32) {
	mut r := u32(c.r)
	r *= u32(c.a)
	r /= 0xffff
	mut g := u32(c.g)
	g *= u32(c.a)
	g /= 0xffff
	mut b := u32(c.b)
	b *= u32(c.a)
	b /= 0xffff
	return r, g, b, u32(c.a)
}

// Alpha represents an 8-bit alpha color.
pub struct Alpha {
	a u8
}

pub fn (c Alpha) rgba() (u32, u32, u32, u32) {
	mut a := u32(c.a)
	a |= a << 8
	return 0, 0, 0, a
}

// Alpha16 represents a 16-bit alpha color.
pub struct Alpha16 {
	a u16
}

pub fn (c Alpha16) rgba() (u32, u32, u32, u32) {
	return 0, 0, 0, u32(c.a)
}

// Gray represents an 8-bit grayscale color.
pub struct Gray {
	y u8
}

pub fn (c Gray) rgba() (u32, u32, u32, u32) {
	mut y := u32(c.y)
	y |= y << 8
	return y, y, y, 0xffff
}

// Gray16 represents a 16-bit grayscale color.
pub struct Gray16 {
	y u16
}

pub fn (c Gray16) rgba() (u32, u32, u32, u32) {
	y := u32(c.y)
	return y, y, y, 0xffff
}

// Model can convert any Color to one from its own color model. The conversion
// may be lossy.
interface Model {
	convert(Color) Color
}

pub struct ModelFunc {
	f fn(Color) Color
}

pub fn (m ModelFunc) convert(c Color) Color {
	return m.f(c)
}

// ModelFunc returns a Model that invokes f to implement the conversion.
pub fn make_model(f fn(Color) Color) Model {
	return ModelFunc{f: f}
}

pub fn make_rbga_model(c Color) Color {
	r, g, b, a := c.rgba()
	return RGBA{r: u8(r >> 8), g: u8(g >> 8), b: u8(b >> 8), a: u8(a >> 8)}
}

pub fn make_rgba_64_model(c Color) Color {
	r, g, b, a := c.rgba()
	return RGBA64{r: u16(r), g: u16(g), b: u16(b), a: u16(a)}
}

pub fn make_nrgba_model(c Color) Color {
	r, g, b, a := c.rgba()
	if a == 0xffff {
		return RGBA{r: u8(r >> 8), g: u8(g >> 8), b: u8(b >> 8), a: 0xff}
	}
	if a == 0 {
		return RGBA{r: 0, g: 0, b: 0, a: 0}
	}
	// Since Color.rgba returns an alpha-premultiplied color, we should have
	// r <= a && g <= a && b <= a.
	r2 := (r * 0xffff) / a
	g2 := (g * 0xffff) / a
	b2 := (b * 0xffff) / a
	return RGBA{r: u8(r2 >> 8), g: u8(g2 >> 8), b: u8(b2 >> 8), a: u8(a >> 8)}
}

pub fn make_nrgba_64_model(c Color) Color {
	r, g, b, a := c.rgba()
	if a == 0xffff {
		return RGBA64{r: u16(r), g: u16(g), b: u16(b), a: 0xffff}
	}
	if a == 0 {
		return RGBA64{r: 0, g: 0, b: 0, a: 0}
	}
	// Since Color.rgba returns an alpha-premultiplied color, we should have
	// r <= a && g <= a && b <= a.
	r2 := (r * 0xffff) / a
	g2 := (g * 0xffff) / a
	b2 := (b * 0xffff) / a
	return RGBA64{r: u16(r2), g: u16(g2), b: u16(b2), a: u16(a)}
}

pub fn make_alpha_model(c Color) Color {
	_, _, _, a := c.rgba()
	return Alpha{a: u8(a >> 8)}
}

pub fn make_alpha_16_model(c Color) Color {
	_, _, _, a := c.rgba()
	return Alpha16{a: u16(a)}
}

pub fn make_gray_model(c Color) Color {
	r, g, b, _ := c.rgba()

	// These coefficients (the fractions 0.299, 0.587 and 0.114) are the same
	// as those given by the JFIF specification and used by func RGBToYCbCr in
	// ycbcr.go.
	//
	// Note that 19595 + 38470 + 7471 equals 65536.
	//
	// The 24 is 16 + 8. The 16 is the same as used in RGBToYCbCr. The 8 is
	// because the return value is 8 bit color, not 16 bit color.
	y := (19595*r + 38470*g + 7471*b + 1<<15) >> 24
	return Gray{y: u8(y)}
}

pub fn make_gray_16_model(c Color) Color {
	r, g, b, _ := c.rgba()

	// These coefficients (the fractions 0.299, 0.587 and 0.114) are the same
	// as those given by the JFIF specification and used by func RGBToYCbCr in
	// ycbcr.go.
	//
	// Note that 19595 + 38470 + 7471 equals 65536.
	y := (19595*r + 38470*g + 7471*b + 1<<15) >> 16
	return Gray16{y: u16(y)}
}

// Palette is a palette of colors.
pub type Palette = []Color

// Convert returns the palette color closest to c in Euclidean R,G,B space.
pub fn (p Palette) convert(c Color) ?Color {
	if p.len == 0 {
		return none
	}
	return p[p.index(c)]
}

// sq_diff returns the squared-difference of x and y, shifted by 2 so that
// adding four of those won't overflow a u32.
//
// x and y are assumed to be in range [0, 0xffff].
pub fn sq_diff(x u32, y u32) u32 {
	d := x - y
	return (d * d) >> 2
}

// Index returns the index of the palette color closest to c in Euclidean
// R,G,B,A space.
pub fn (p Palette) index(c Color) int {
	// A batch version of this computation is in image/draw/draw.v.

	cr, cg, cb, ca := c.rgba()
	mut ret := 0
	mut best := u32(1<<32 - 1)
	for i, v in p {
		vr, vg, vb, va := v.rgba()
		sum := sq_diff(cr, vr) + sq_diff(cg, vg) + sq_diff(cb, vb) + sq_diff(ca, va)
		if sum < best {
			if sum == 0 {
				return i
			}
			ret = i
			best = sum
		}
	}
	return ret
}

// Models for the standard color types.
pub const rgba_model = ModelFunc{f: make_rbga_model}
pub const rgba_64_model = ModelFunc{f: make_rgba_64_model}
pub const nrgba_model = ModelFunc{f: make_nrgba_model}
pub const nrgba_64_model = ModelFunc{f: make_nrgba_64_model}
pub const alpha_model = ModelFunc{f: make_alpha_model}
pub const alpha_16_model = ModelFunc{f: make_alpha_16_model}
pub const gray_model = ModelFunc{f: make_gray_model}
pub const gray_16_model = ModelFunc{f: make_gray_16_model}

// Predefined colors.
pub const black = Gray16{y: 0x00}
pub const white = Gray16{y: 0xffff}
pub const transparent = Alpha16{a: 0x0000}
pub const opaque = Alpha16{a: 0xffff}
