package main

import gl "vendor:OpenGL"

Material :: struct {
	diffuse:   int,
	specular:  int,
	shininess: f32,
}

create_lighting_ssbos :: proc() -> (directionalSSBO: u32, pointSSBO: u32, spotSSBO: u32) {
	gl.GenBuffers(1, &directionalSSBO)
	gl.GenBuffers(1, &pointSSBO)
	gl.GenBuffers(1, &spotSSBO)

	return
}
