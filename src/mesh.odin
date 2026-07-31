package main

import "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Mesh :: struct {
	mat:      glsl.mat4,

	// shading
	material: Material,
	pass:     RenderPass,

	// internal
	vbo:      u32,
	vertices: i32,
}

make_mesh :: proc(
	pass: RenderPass,
	shadedVAO: u32,
	mat: glsl.mat4,
	material: Material,
	vertices: []Vertex,
) -> Mesh {
	vertices := vertices
	vbo: u32
	gl.GenBuffers(1, &vbo)

	mesh := Mesh {
		mat      = mat,
		material = material,
		pass     = pass,
		vbo      = vbo,
		vertices = 0,
	}
	set_mesh_vertices(&mesh, vertices)

	gl.BindVertexArray(shadedVAO)
	init_shaded_vertex_vao()

	return mesh
}

set_mesh_vertices :: proc(mesh: ^Mesh, vertices: []Vertex) {
	vertices := vertices
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(Vertex),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)
	mesh.vertices = cast(i32)len(vertices)
}

mesh_render :: proc(mesh: ^Mesh, shader: ^Shader) {
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
	shader_set_mat4(shader, "model", mesh.mat)
	bind_material(&mesh.material, shader)
	gl.DrawArrays(gl.TRIANGLES, 0, mesh.vertices)
}

mesh_delete :: proc(mesh: ^Mesh) {
	gl.DeleteBuffers(1, &mesh.vbo)
}
