package main

import gl "vendor:OpenGL"

Texture :: struct {
	id: u32,
}

make_texture :: proc(
	image_width: i32,
	image_height: i32,
	format: u32,
	image_data: [^]byte,
) -> Texture {
	// our first texture!
	id: u32 = ---
	gl.GenTextures(1, &id)
	gl.BindTexture(gl.TEXTURE_2D, id)

	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.RGB,
		image_width,
		image_height,
		0,
		format,
		gl.UNSIGNED_BYTE,
		image_data,
	)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	return Texture{id}
}

texture_use :: proc(texture: ^Texture) {
	gl.BindTexture(gl.TEXTURE_2D, texture.id)
}

texture_use_slotted :: proc(texture: ^Texture, slot: u32) {
	assert(slot <= 31)

	gl.ActiveTexture(gl.TEXTURE0 + slot)
	gl.BindTexture(gl.TEXTURE_2D, texture.id)
}
