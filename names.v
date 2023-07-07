module image

import image.color

pub const (
	// black is an opaque black uniform image.
	black = new_uniform(color.black)

	// white is an opaque white uniform image.
	white = new_uniform(color.white)

	// transparent is a fully transparent uniform image.
	transparent = new_uniform(color.transparent)

	// opaque is a fully opaque uniform image.
	opaque = new_uniform(color.opaque)
)

// Uniform is an infinite-sized Image of uniform color.
// It implements the color.Color, color.Model, and Image interfaces.
pub struct Uniform {
	c color.Color
}

pub fn (u &Uniform) rgba() (u32, u32, u32, u32) {
	return u.c.rgba()
}

pub fn (u &Uniform) color_model() &color.Model {
	return u
}

pub fn (u &Uniform) convert(c color.Color) color.Color {
	return u.c
}

pub fn (u &Uniform) bounds() Rectangle {
	return Rectangle{min: Point{-1e9, -1e9}, max: Point{1e9, 1e9}}
}

pub fn (u &Uniform) at(x, y i32) color.Color {
	return u.c
}

pub fn (u &Uniform) rgb64_at(x, y i32) color.Color {
	r, g, b, a := u.c.rgba()
	return color.RGBA64{r: u16(r), g: u16(g), b: u16(b), a: u16(a)}
}

// Opaque scans the entire image and reports whether it is fully opaque.
pub fn (u &Uniform) opaque() bool {
	_, _, _, a := u.c.rgba()
	return a == 0xffff
}

pub fn new_uniform(c color.Color) &Uniform {
	return &Uniform{ c }
}
