module image

// A Point is an X, Y coordinate pair. The axes increase right and down.
pub struct Point {
	x int
	y int
}

// String returns a string representation of p like "(3,4)".
pub fn (p Point) str() string {
	return '(${p.x}, ${p.y})'
}

// Add returns the vector p+q.
pub fn (p Point) add(q Point) Point {
	return Point{p.x + q.x, p.y + q.y}
}

// Sub returns the vector p-q.
pub fn (p Point) sub(q Point) Point {
	return Point{p.x - q.x, p.y - q.y}
}

// Mul returns the vector p*k.
pub fn (p Point) mul(k int) Point {
	return Point{p.x * k, p.y * k}
}

// In reports whether p is in r.
pub fn (p Point) in(r Rectangle) bool {
	return r.min.x <= p.x && p.x < r.max.x && r.min.y <= p.y && p.y < r.max.y
}

// Mod returns the point q in r that is equivalent to p modulo r.
pub fn (p &Point) mod(r Rectangle) Point {
	w, h := r.dx(), r.dy()
	p = p.sub(r.Min)
	p.x = p.x % w
	if p.x < 0 {
		p.x += w
	}
	p.y = p.y % h
	if p.y < 0 {
		p.y += h
	}
	return p.add(r.min)
}

// Eq reports whether p and q are equal.
pub fn (p Point) eq(q Point) bool {
	return p.x == q.x && p.y == q.y
}

// A Rectangle contains the points with Min.X <= X < Max.X, Min.Y <= Y < Max.Y.
// It is well-formed if Min.X <= Max.X and likewise for Y. Points are always
// well-formed. A rectangle's methods always return well-formed outputs for
// well-formed inputs.
//
// A Rectangle is also an Image whose bounds are the rectangle itself. At
// returns color.Opaque for points in the rectangle and color.Transparent
// otherwise.
pub struct Rectangle {
	min Point
	max Point
}

// String returns a string representation of r like "(3,4)-(6,5)".
pub fn (r Rectangle) str() string {
	return '${r.min.str()}-${r.max.str()}'
}

// Dx returns r's width.
pub fn (r Rectangle) dx() int {
	return r.max.x - r.min.x
}

// Dy returns r's height.
pub fn (r Rectangle) dy() int {
	return r.max.y - r.min.y
}

// Size returns r's width and height.
pub fn (r Rectangle) size() Point {
	return Point{r.dx(), r.dy()}
}

// Add returns the rectangle r translated by p.
pub fn (r Rectangle) add(p Point) Rectangle {
	return Rectangle{r.min.add(p), r.max.add(p)}
}

// Sub returns the rectangle r translated by -p.
pub fn (r Rectangle) sub(p Point) Rectangle {
	return Rectangle{r.min.sub(p), r.max.sub(p)}
}

// Inset returns the rectangle r inset by n, which may be negative. If either
// of r's dimensions is less than 2*n then an empty rectangle near the center
// of r will be returned.
pub fn (r Rectangle) inset(n int) Rectangle {
	if r.dx() < 2*n {
		r.min.x = (r.min.x + r.max.x) / 2
		r.max.x = r.min.x
	} else {
		r.min.x += n
		r.max.x -= n
	}
	if r.dy() < 2*n {
		r.min.y = (r.min.y + r.max.y) / 2
		r.max.y = r.min.y
	} else {
		r.min.y += n
		r.max.y -= n
	}
	return r
}
