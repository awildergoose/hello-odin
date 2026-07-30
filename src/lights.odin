package main

import "core:math/linalg/glsl"

AbstractLight :: struct #align (8) {
	ambient:  glsl.vec3,
	diffuse:  glsl.vec3,
	specular: glsl.vec3,
}

AttentuatedLight :: struct {
	constant:  f32,
	linear:    f32,
	quadratic: f32,
}

DirectionalLight :: struct #align (8) {
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

make_directional_light :: proc() -> DirectionalLight {
	return DirectionalLight {
		ambient = glsl.vec3{0.3, 0.24, 0.14},
		diffuse = glsl.vec3{0.7, 0.42, 0.26},
		specular = glsl.vec3(0.5),
		direction = glsl.vec3{-0.2, -1.0, -0.3},
	}
}
