package main

import "core:math/linalg/glsl"

Mesh :: struct {
	position: glsl.vec3,

	// shading
	material: Material,
	shader:   ^Shader,

	// internal
	vbo:      u32,
	textures: map[u32]^Texture, // <slot, texture pointer>
}

make_mesh :: proc(position: glsl.vec3, material: Material, shader: ^Shader) -> Mesh {
	return Mesh {
		position = position,
		material = material,
		shader = shader,
		textures = make(map[u32]^Texture),
		vbo = 0,
	}
}
