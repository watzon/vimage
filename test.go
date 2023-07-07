package main

import (
	"fmt"
	"image/color"
)

func main() {
	y, cb, cr := color.RGBToYCbCr(0, 0, 3)
	// r, g, b := color.YCbCrToRGB(199, 0, 0)
	fmt.Println(y, cb, cr)
	// fmt.Println(r, g, b)
}
