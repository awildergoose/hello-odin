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

make_directional_light :: proc() -> DirectionalLight {
	return DirectionalLight {
		ambient = glsl.vec4{0.3, 0.24, 0.14, 0.0},
		diffuse = glsl.vec4{0.7, 0.42, 0.26, 0.0},
		specular = glsl.vec4(0.5),
		direction = glsl.vec4{-0.2, -1.0, -0.3, 0.0},
	}
}
