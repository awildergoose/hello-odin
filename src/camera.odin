package main

import "core:math"
import "core:math/linalg/glsl"
import "vendor:glfw"

Camera :: struct {
	yaw:   f32,
	pitch: f32,
	lastX: f32,
	lastY: f32,
	fov:   f32,
	pos:   glsl.vec3,
	front: glsl.vec3,
	up:    glsl.vec3,
}

DEFAULT_CAMERA :: Camera {
	yaw   = -90.0,
	pitch = 0.0,
	fov   = 45.0,
	pos   = glsl.vec3{0.0, 0.0, 3.0},
	front = glsl.vec3{0.0, 0.0, -1.0},
	up    = glsl.vec3{0.0, 1.0, 0.0},
}

camera_move_with_mouse :: proc(camera: ^Camera, xpos: f32, ypos: f32) {
	xoffset := xpos - camera.lastX
	yoffset := camera.lastY - ypos
	camera.lastX = xpos
	camera.lastY = ypos

	sensitivity: f32 = 0.1
	xoffset *= sensitivity
	yoffset *= sensitivity

	camera.yaw += xoffset
	camera.pitch += yoffset

	if camera.pitch > 89.0 {
		camera.pitch = 89.0
	}
	if camera.pitch < -89.0 {
		camera.pitch = -89.0
	}

	direction := glsl.vec3{}
	direction.x = math.cos(glsl.radians(camera.yaw)) * math.cos(glsl.radians(camera.pitch))
	direction.y = math.sin(glsl.radians(camera.pitch))
	direction.z = math.sin(glsl.radians(camera.yaw)) * math.cos(glsl.radians(camera.pitch))
	camera.front = glsl.normalize(direction)
}

camera_input :: proc(camera: ^Camera, window: glfw.WindowHandle) {
	cameraSpeed: f32 = 2.5 * state.deltaTime

	if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS {
		camera.pos += cameraSpeed * camera.front
	}
	if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS {
		camera.pos -= cameraSpeed * camera.front
	}
	if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS {
		camera.pos -= glsl.normalize(glsl.cross(camera.front, camera.up)) * cameraSpeed
	}
	if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS {
		camera.pos += glsl.normalize(glsl.cross(camera.front, camera.up)) * cameraSpeed
	}
}

camera_get_view :: proc(camera: ^Camera) -> glsl.mat4 {
	return glsl.mat4LookAt(camera.pos, camera.pos + camera.front, camera.up)
}

camera_get_projection :: proc(
	camera: ^Camera,
	screen_width: i32,
	screen_height: i32,
) -> glsl.mat4 {
	return glsl.mat4Perspective(
		glsl.radians_f32(camera.fov),
		cast(f32)screen_width / cast(f32)screen_height,
		0.1,
		100.0,
	)
}

camera_get_model :: proc() -> glsl.mat4 {
	return glsl.mat4Rotate(glsl.vec3{1.0, 0.0, 0.0}, glsl.radians_f32(-55.0))
}
