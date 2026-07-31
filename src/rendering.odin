package main

import gl "vendor:OpenGL"

RenderPass :: enum {
	Shaded,
}

init_shared_pass :: proc(shader: ^Shader, time: f32) {
	// MVP
	shader_set_mat4(shader, "view", camera_get_view(&state.camera))
	shader_set_mat4(
		shader,
		"projection",
		camera_get_projection(&state.camera, SCREEN_WIDTH, SCREEN_HEIGHT),
	)

	shader_set_vec3(shader, "viewPos", state.camera.pos)
	shader_set_float(shader, "time", time)
}

init_shaded_pass :: proc(
	shader: ^Shader,
	std430: ^Std430Builder,
	directionalSSBO: u32,
	pointSSBO: u32,
	spotSSBO: u32,
) {
	shader_set_uint(shader, "dCount", cast(u32)len(&state.directionalLights))
	shader_set_uint(shader, "pCount", cast(u32)len(&state.pointLights))
	shader_set_uint(shader, "sCount", cast(u32)len(&state.spotLights))

	for &light in state.directionalLights {
		encode_directional_light(std430, &light)
	}

	gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, directionalSSBO)
	gl.BufferData(
		gl.SHADER_STORAGE_BUFFER,
		std430.offset,
		raw_data(std430.data[:std430.offset]),
		gl.DYNAMIC_DRAW,
	)
	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, directionalSSBO)

	std430_clear(std430)

	for &light in state.pointLights {
		encode_point_light(std430, &light)
	}

	gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, pointSSBO)
	gl.BufferData(
		gl.SHADER_STORAGE_BUFFER,
		std430.offset,
		raw_data(std430.data[:std430.offset]),
		gl.DYNAMIC_DRAW,
	)
	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 2, pointSSBO)

	std430_clear(std430)

	for &light in state.spotLights {
		encode_spot_light(std430, &light)
	}

	gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, spotSSBO)
	gl.BufferData(
		gl.SHADER_STORAGE_BUFFER,
		std430.offset,
		raw_data(std430.data[:std430.offset]),
		gl.DYNAMIC_DRAW,
	)
	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 3, spotSSBO)
}
