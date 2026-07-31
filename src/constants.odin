package main

import "core:math/linalg/glsl"

SCREEN_WIDTH: i32 = 800
SCREEN_HEIGHT: i32 = 600
WINDOW_TITLE: cstring = "Learn OpenGL"

vertices := [?]Vertex {
	Vertex{glsl.vec3{-0.5, -0.5, -0.5}, glsl.vec3{0.0, 0.0, -1.0}, glsl.vec2{0.0, 0.0}},
	Vertex{glsl.vec3{0.5, -0.5, -0.5}, glsl.vec3{0.0, 0.0, -1.0}, glsl.vec2{1.0, 0.0}},
	Vertex{glsl.vec3{0.5, 0.5, -0.5}, glsl.vec3{0.0, 0.0, -1.0}, glsl.vec2{1.0, 1.0}},
	Vertex{glsl.vec3{0.5, 0.5, -0.5}, glsl.vec3{0.0, 0.0, -1.0}, glsl.vec2{1.0, 1.0}},
	Vertex{glsl.vec3{-0.5, 0.5, -0.5}, glsl.vec3{0.0, 0.0, -1.0}, glsl.vec2{0.0, 1.0}},
	Vertex{glsl.vec3{-0.5, -0.5, -0.5}, glsl.vec3{0.0, 0.0, -1.0}, glsl.vec2{0.0, 0.0}},
	Vertex{glsl.vec3{-0.5, -0.5, 0.5}, glsl.vec3{0.0, 0.0, 1.0}, glsl.vec2{0.0, 0.0}},
	Vertex{glsl.vec3{0.5, -0.5, 0.5}, glsl.vec3{0.0, 0.0, 1.0}, glsl.vec2{1.0, 0.0}},
	Vertex{glsl.vec3{0.5, 0.5, 0.5}, glsl.vec3{0.0, 0.0, 1.0}, glsl.vec2{1.0, 1.0}},
	Vertex{glsl.vec3{0.5, 0.5, 0.5}, glsl.vec3{0.0, 0.0, 1.0}, glsl.vec2{1.0, 1.0}},
	Vertex{glsl.vec3{-0.5, 0.5, 0.5}, glsl.vec3{0.0, 0.0, 1.0}, glsl.vec2{0.0, 1.0}},
	Vertex{glsl.vec3{-0.5, -0.5, 0.5}, glsl.vec3{0.0, 0.0, 1.0}, glsl.vec2{0.0, 0.0}},
	Vertex{glsl.vec3{-0.5, 0.5, 0.5}, glsl.vec3{1.0, 0.0, 0.0}, glsl.vec2{1.0, 0.0}},
	Vertex{glsl.vec3{-0.5, 0.5, -0.5}, glsl.vec3{1.0, 0.0, 0.0}, glsl.vec2{1.0, 1.0}},
	Vertex{glsl.vec3{-0.5, -0.5, -0.5}, glsl.vec3{1.0, 0.0, 0.0}, glsl.vec2{0.0, 1.0}},
	Vertex{glsl.vec3{-0.5, -0.5, -0.5}, glsl.vec3{1.0, 0.0, 0.0}, glsl.vec2{0.0, 1.0}},
	Vertex{glsl.vec3{-0.5, -0.5, 0.5}, glsl.vec3{1.0, 0.0, 0.0}, glsl.vec2{0.0, 0.0}},
	Vertex{glsl.vec3{-0.5, 0.5, 0.5}, glsl.vec3{1.0, 0.0, 0.0}, glsl.vec2{1.0, 0.0}},
	Vertex{glsl.vec3{0.5, 0.5, 0.5}, glsl.vec3{1.0, 0.0, 0.0}, glsl.vec2{1.0, 0.0}},
	Vertex{glsl.vec3{0.5, 0.5, -0.5}, glsl.vec3{1.0, 0.0, 0.0}, glsl.vec2{1.0, 1.0}},
	Vertex{glsl.vec3{0.5, -0.5, -0.5}, glsl.vec3{1.0, 0.0, 0.0}, glsl.vec2{0.0, 1.0}},
	Vertex{glsl.vec3{0.5, -0.5, -0.5}, glsl.vec3{1.0, 0.0, 0.0}, glsl.vec2{0.0, 1.0}},
	Vertex{glsl.vec3{0.5, -0.5, 0.5}, glsl.vec3{1.0, 0.0, 0.0}, glsl.vec2{0.0, 0.0}},
	Vertex{glsl.vec3{0.5, 0.5, 0.5}, glsl.vec3{1.0, 0.0, 0.0}, glsl.vec2{1.0, 0.0}},
	Vertex{glsl.vec3{-0.5, -0.5, -0.5}, glsl.vec3{0.0, -1.0, 0.0}, glsl.vec2{0.0, 1.0}},
	Vertex{glsl.vec3{0.5, -0.5, -0.5}, glsl.vec3{0.0, -1.0, 0.0}, glsl.vec2{1.0, 1.0}},
	Vertex{glsl.vec3{0.5, -0.5, 0.5}, glsl.vec3{0.0, -1.0, 0.0}, glsl.vec2{1.0, 0.0}},
	Vertex{glsl.vec3{0.5, -0.5, 0.5}, glsl.vec3{0.0, -1.0, 0.0}, glsl.vec2{1.0, 0.0}},
	Vertex{glsl.vec3{-0.5, -0.5, 0.5}, glsl.vec3{0.0, -1.0, 0.0}, glsl.vec2{0.0, 0.0}},
	Vertex{glsl.vec3{-0.5, -0.5, -0.5}, glsl.vec3{0.0, -1.0, 0.0}, glsl.vec2{0.0, 1.0}},
	Vertex{glsl.vec3{-0.5, 0.5, -0.5}, glsl.vec3{0.0, 1.0, 0.0}, glsl.vec2{0.0, 1.0}},
	Vertex{glsl.vec3{0.5, 0.5, -0.5}, glsl.vec3{0.0, 1.0, 0.0}, glsl.vec2{1.0, 1.0}},
	Vertex{glsl.vec3{0.5, 0.5, 0.5}, glsl.vec3{0.0, 1.0, 0.0}, glsl.vec2{1.0, 0.0}},
	Vertex{glsl.vec3{0.5, 0.5, 0.5}, glsl.vec3{0.0, 1.0, 0.0}, glsl.vec2{1.0, 0.0}},
	Vertex{glsl.vec3{-0.5, 0.5, 0.5}, glsl.vec3{0.0, 1.0, 0.0}, glsl.vec2{0.0, 0.0}},
	Vertex{glsl.vec3{-0.5, 0.5, -0.5}, glsl.vec3{0.0, 1.0, 0.0}, glsl.vec2{0.0, 1.0}},
}
// indices := [?]u32{
//     0, 1, 3,   // first triangle
//     1, 2, 3    // second triangle
// }
// tex_coords := [?]f32{
//     0.0, 0.0,  // lower-left corner
//     1.0, 0.0,  // lower-right corner
//     0.5, 1.0   // top-center corner
// }
cubePositions := [?]glsl.vec3 {
	glsl.vec3{0.0, 0.0, 0.0},
	glsl.vec3{2.0, 5.0, -15.0},
	glsl.vec3{-1.5, -2.2, -2.5},
	glsl.vec3{-3.8, -2.0, -12.3},
	glsl.vec3{2.4, -0.4, -3.5},
	glsl.vec3{-1.7, 3.0, -7.5},
	glsl.vec3{1.3, -2.0, -2.5},
	glsl.vec3{1.5, 2.0, -2.5},
	glsl.vec3{1.5, 0.2, -1.5},
	glsl.vec3{-1.3, 1.0, -1.5},
}
pointLightPositions := [?]glsl.vec3 {
	glsl.vec3{1.0, 0.6, 0.0},
	glsl.vec3{1.0, 0.0, 0.0},
	glsl.vec3{1.0, 1.0, 0.0},
	glsl.vec3{0.2, 0.2, 1.0},
}
pointLightColors := [?]glsl.vec3 {
	glsl.vec3{0.1, 0.1, 0.1},
	glsl.vec3{0.1, 0.1, 0.1},
	glsl.vec3{0.1, 0.1, 0.1},
	glsl.vec3{0.3, 0.1, 0.1},
}
