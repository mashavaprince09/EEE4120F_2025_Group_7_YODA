default:
	iverilog -o bin/boo.out src/boo.v src/sobel.v
run:
	vvp bin/boo.out
validate:
	diff out/sobel.hex out/golden_sobel.hex