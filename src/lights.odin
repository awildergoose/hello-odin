package main

import "core:math/linalg/glsl"

AbstractLight :: struct {
	ambient:  glsl.vec3,
	diffuse:  glsl.vec3,
	specular: glsl.vec3,
}

AttentuatedLight :: struct {
	constant:  f32,
	linear:    f32,
	quadratic: f32,
}

DirectionalLight :: struct {
	using base: AbstractLight,
	direction:  glsl.vec3,
}

PointLight :: struct {
	using base:         AbstractLight,
	using attentuation: AttentuatedLight,
	position:           glsl.vec3,
}

SpotLight :: struct {
	using base:         AbstractLight,
	using attentuation: AttentuatedLight,
	position:           glsl.vec3,
	direction:          glsl.vec3,
	cutOff:             f32,
	outerCutOff:        f32,
}

vec3_to_vec4 :: proc(vec: glsl.vec3) -> glsl.vec4 {
	return glsl.vec4{vec.x, vec.y, vec.z, 0.0}
}

make_directional_light :: proc(
	ambient: glsl.vec3,
	diffuse: glsl.vec3,
	specular: glsl.vec3,
	direction: glsl.vec3,
) -> DirectionalLight {
	return DirectionalLight {
		ambient = ambient,
		diffuse = diffuse,
		specular = specular,
		direction = direction,
	}
}

make_point_light :: proc(
	position: glsl.vec3,
	ambient: glsl.vec3,
	diffuse: glsl.vec3,
	specular: glsl.vec3,
	constant: f32,
	linear: f32,
	quadratic: f32,
) -> PointLight {
	return PointLight {
		ambient = ambient,
		diffuse = diffuse,
		specular = specular,
		constant = constant,
		linear = linear,
		quadratic = quadratic,
		position = position,
	}
}

make_spot_light :: proc(
	position: glsl.vec3,
	ambient: glsl.vec3,
	diffuse: glsl.vec3,
	specular: glsl.vec3,
	constant: f32,
	linear: f32,
	quadratic: f32,
	direction: glsl.vec3,
	cutOff: f32,
	outerCutOff: f32,
) -> SpotLight {
	return SpotLight {
		ambient = ambient,
		diffuse = diffuse,
		specular = specular,
		constant = constant,
		linear = linear,
		quadratic = quadratic,
		position = position,
		direction = direction,
		cutOff = cutOff,
		outerCutOff = outerCutOff,
	}
}

encode_directional_light :: proc(b: ^Std430Builder, l: ^DirectionalLight) {
	std430_write_vec3(b, l.ambient)
	std430_write_vec3(b, l.diffuse)
	std430_write_vec3(b, l.specular)

	std430_write_vec3(b, l.direction)
}

encode_point_light :: proc(b: ^Std430Builder, l: ^PointLight) {
	std430_write_vec3(b, l.ambient)
	std430_write_vec3(b, l.diffuse)
	std430_write_vec3(b, l.specular)

	std430_write_f32(b, l.constant)
	std430_write_f32(b, l.linear)
	std430_write_f32(b, l.quadratic)

	std430_write_vec3(b, l.position)
}

encode_spot_light :: proc(b: ^Std430Builder, l: ^SpotLight) {
	std430_write_vec3(b, l.ambient)
	std430_write_vec3(b, l.diffuse)
	std430_write_vec3(b, l.specular)

	std430_write_f32(b, l.constant)
	std430_write_f32(b, l.linear)
	std430_write_f32(b, l.quadratic)

	std430_write_vec3(b, l.position)
	std430_write_vec3(b, l.direction)
	std430_write_f32(b, l.cutOff)
	std430_write_f32(b, l.outerCutOff)
}
