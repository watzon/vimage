module color

fn test_sq_diff() {
	// Canonical sq diff implementation
	orig := fn(x u32, y u32) u32 {
		d := if x > y { x - y } else { y - x }
		return (d * d) >> 2
	}

	test_cases := [
		u32(0),
		1,
		2,
		0x0fffd,
		0x0fffe,
		0x0ffff,
		0x10000,
		0x10001,
		0x10002,
		0xfffffffd,
		0xfffffffe,
		0xffffffff,
	]

	for x in test_cases {
		for y in test_cases {
			assert(orig(x, y) == sq_diff(x, y))
		}
	}
}
