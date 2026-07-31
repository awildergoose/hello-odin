package main

import gl "vendor:OpenGL"

create_lighting_ssbos :: proc() -> (directionalSSBO: u32, pointSSBO: u32, spotSSBO: u32) {
	gl.GenBuffers(1, &directionalSSBO)
	gl.GenBuffers(1, &pointSSBO)
	gl.GenBuffers(1, &spotSSBO)

	return
}
