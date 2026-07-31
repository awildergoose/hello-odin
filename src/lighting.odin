package main

import gl "vendor:OpenGL"

Material :: struct {
	diffuse:   i32,
	specular:  i32,
	shininess: f32,
}

create_lighting_ssbos :: proc() -> (directionalSSBO: u32, pointSSBO: u32, spotSSBO: u32) {
	gl.GenBuffers(1, &directionalSSBO)
	gl.GenBuffers(1, &pointSSBO)
	gl.GenBuffers(1, &spotSSBO)

	return
}

bind_material :: proc(material: ^Material, shader: ^Shader) {
	shader_set_int(shader, "material.diffuse", material.diffuse)
	shader_set_int(shader, "material.specular", material.specular)
	shader_set_float(shader, "material.shininess", material.shininess)
}
