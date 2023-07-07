module main

// This program generates palette.v. Invoke it with
// v run gen.v -output palette.v

import flag
import os
import strings

fn print_plan9(mut sb strings.Builder) {
	mut c := [3]int{}
	mut lines := [256]string{}
	for r, i := 0, 0; r != 4; r++ {
		for v := 0; v != 4; v, i = v + 1, i + 16 {
			for g, j := 0, v - r; g != 4; g++ {
				for b := 0; b != 4; b, j = b + 1, j + 1 {
					mut den := r
					if g > den {
						den = g
					}
					if b > den {
						den = b
					}
					if den == 0 {
						c[0] = 0x11 * v
						c[1] = 0x11 * v
						c[2] = 0x11 * v
					} else {
						mut num := 17 * (4 * den + v)
						c[0] = r * num / den
						c[1] = g * num / den
						c[2] = b * num / den
					}
					lines[i + (j & 0x0f)] = '\tcolor.RGBA{0x${c[0]:02x}, 0x${c[1]:02x}, 0x${c[2]:02x}, 0xff},'
				}
			}
		}
	}
	sb.write_string('// `plan9` is a 256-color palette that partitions the 24-bit RGB space\n')
	sb.write_string('// into 4×4×4 subdivision, with 4 shades in each subcube. Compared to the\n')
	sb.write_string('// WebSafe, the idea is to reduce the color resolution by dicing the\n')
	sb.write_string('// color cube into fewer cells, and to use the extra space to increase the\n')
	sb.write_string('// intensity resolution. This results in 16 gray shades (4 gray subcubes with\n')
	sb.write_string('// 4 samples in each), 13 shades of each primary and secondary color (3\n')
	sb.write_string('// subcubes with 4 samples plus black) and a reasonable selection of colors\n')
	sb.write_string('// covering the rest of the color cube. The advantage is better representation\n')
	sb.write_string('// of continuous tones.\n')
	sb.write_string('//\n')
	sb.write_string('// This palette was used in the Plan 9 Operating System, described at\n')
	sb.write_string('// https://9p.io/magic/man2html/6/color\n')
	sb.write_string('pub const plan9 = [\n')
	for _, line in lines {
		sb.write_string(line)
		sb.write_string('\n')
	}
	sb.write_string(']\n')
	sb.write_string('\n')
}

fn print_web_safe(mut sb strings.Builder) {
	mut lines := [6 * 6 * 6]string{}
	for r := 0; r < 6; r++ {
		for g := 0; g < 6; g++ {
			for b := 0; b < 6; b++ {
				lines[36 * r + 6 * g + b] =	'\tcolor.RGBA{0x${r * 0x33:02x}, 0x${g * 0x33:02x}, 0x${b * 0x33:02x}, 0xff},'
			}
		}
	}
	sb.write_string('// `websafe` is a 216-color palette that was popularized by early versions\n')
	sb.write_string('// of Netscape Navigator. It is also known as the Netscape Color Cube.\n')
	sb.write_string('//\n')
	sb.write_string('// See https://en.wikipedia.org/wiki/Web_colors#Web-safe_colors for details.\n')
	sb.write_string('pub const websafe = [\n')
	for _, line in lines {
		sb.write_string(line)
		sb.write_string('\n')
	}
	sb.write_string(']\n')
	sb.write_string('\n')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	filename := fp.string('output',  `o`, 'palette.v', 'output file name\n')

	mut sb := strings.new_builder(1024)
	sb.write_string('// Copyright 2023 Chris Watson. All rights reserved.\n// Use of this source code is governed by the MIT\n// license that can be found in the LICENSE file.\n')
	sb.write_string('\n')
	sb.write_string('// Code generated by `v run gen.v -output palette.v`; DO NOT EDIT DIRECTLY.\n')
	sb.write_string('\n')
	sb.write_string('module palette\n')
	sb.write_string('\n')
	sb.write_string('import image.color\n')
	sb.write_string('\n')
	print_plan9(mut sb)
	print_web_safe(mut sb)

	os.write_file(filename, sb.str()) or {
		println('error writing file: $err')
	}
}