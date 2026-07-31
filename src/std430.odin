package main

import "core:math/linalg/glsl"
import "core:mem"

Std430Builder :: struct {
	data:          [dynamic]byte,
	offset:        int,
	// FUCK YOU FUCK YOU FUCK YOU FUCK YOU
	last_was_vec3: bool,
}

make_std430 :: proc(cap: int) -> Std430Builder {
	data := make([dynamic]byte, cap)
	return Std430Builder{data = data, offset = 0, last_was_vec3 = false}
}

std430_align :: proc(b: ^Std430Builder, a: int) {
	newOff := (b.offset + (a - 1)) & ~(a - 1)
	assert(newOff <= len(b.data))
	b.offset = newOff
}

std430_addptr :: proc(b: ^Std430Builder, rel: int) -> rawptr {
	base := mem.ptr_offset(&b.data[0], 0)

	return mem.ptr_offset(base, b.offset + rel)
}

std430_write_f32 :: proc(b: ^Std430Builder, v: f32) {
	v := v
	if b.last_was_vec3 {
		b.offset -= 4
		b.last_was_vec3 = false
	}

	std430_align(b, 4)
	assert(b.offset + 4 <= len(b.data))
	mem.copy(std430_addptr(b, 0), &v, 4)

	b.offset += 4
}

std430_write_vec3 :: proc(b: ^Std430Builder, v: glsl.vec3) {
	std430_align(b, 16)
	assert(b.offset + 16 <= len(b.data))

	x, y, z := v.x, v.y, v.z
	pad: f32 = 0.0

	mem.copy(std430_addptr(b, 0), &x, 4)
	mem.copy(std430_addptr(b, 4), &y, 4)
	mem.copy(std430_addptr(b, 8), &z, 4)
	mem.copy(std430_addptr(b, 12), &pad, 4)

	b.offset += 16
	b.last_was_vec3 = true
}

std430_clear :: proc(b: ^Std430Builder) {
	b.offset = 0
}
