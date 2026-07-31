package main

import "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Vertex :: struct {
	position: glsl.vec3,
	normal:   glsl.vec3,
	uv:       glsl.vec2,
}

make_vertex :: proc(x: f32, y: f32, z: f32, nX: f32, nY: f32, nZ: f32, u: f32, v: f32) -> Vertex {
	return Vertex {
		position = glsl.vec3{x, y, z},
		normal = glsl.vec3{nX, nY, nZ},
		uv = glsl.vec2{u, v},
	}
}

init_vertex_vao :: proc() {
	// position
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	// normal
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	// texture coords
	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 6 * size_of(f32))
	gl.EnableVertexAttribArray(2)
}
