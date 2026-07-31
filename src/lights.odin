package main

import "core:math/linalg/glsl"

AbstractLight :: struct {
	ambient:  glsl.vec4,
	diffuse:  glsl.vec4,
	specular: glsl.vec4,
}

AttentuatedLight :: struct {
	constant:  f32,
	linear:    f32,
	quadratic: f32,
}

DirectionalLight :: struct {
	using base: AbstractLight,
	direction:  glsl.vec4,
}

PointLight :: struct {
	using base:         AbstractLight,
	using attentuation: AttentuatedLight,
	position:           glsl.vec4,
}

SpotLight :: struct {
	using base:         AbstractLight,
	using attentuation: AttentuatedLight,
	position:           glsl.vec4,
	direction:          glsl.vec4,
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
		ambient = vec3_to_vec4(ambient),
		diffuse = vec3_to_vec4(diffuse),
		specular = vec3_to_vec4(specular),
		direction = vec3_to_vec4(direction),
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
		ambient = vec3_to_vec4(ambient),
		diffuse = vec3_to_vec4(diffuse),
		specular = vec3_to_vec4(specular),
		constant = constant,
		linear = linear,
		quadratic = quadratic,
		position = vec3_to_vec4(position),
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
		ambient = vec3_to_vec4(ambient),
		diffuse = vec3_to_vec4(diffuse),
		specular = vec3_to_vec4(specular),
		constant = constant,
		linear = linear,
		quadratic = quadratic,
		position = vec3_to_vec4(position),
		direction = vec3_to_vec4(direction),
		cutOff = cutOff,
		outerCutOff = outerCutOff,
	}
}
