package main

import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/linalg/glsl"

@(require) import "core:mem"

import gl "vendor:OpenGL"
import "vendor:glfw"
import stbi "vendor:stb/image"

GameState :: struct {
	deltaTime:  f32,
	lastFrame:  f32,
	firstMouse: bool,
	lastMouseX: f32,
	lastMouseY: f32,
	camera:     Camera,
	lightPos:   glsl.vec3,
}

state := GameState {
	deltaTime  = 0.0,
	lastFrame  = 0.0,
	firstMouse = true,
	lastMouseX = cast(f32)SCREEN_WIDTH / 2.0,
	lastMouseY = cast(f32)SCREEN_HEIGHT / 2.0,
	camera     = DEFAULT_CAMERA,
	lightPos   = glsl.vec3{1.2, 1.0, 2.0},
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width: i32, height: i32) {
	gl.Viewport(0, 0, width, height)
}

mouse_callback :: proc "c" (window: glfw.WindowHandle, xpos64: f64, ypos64: f64) {
	xpos := cast(f32)xpos64
	ypos := cast(f32)ypos64

	if (state.firstMouse) {
		state.camera.lastX = xpos
		state.camera.lastY = ypos
		state.firstMouse = false
	}

	context = runtime.default_context()
	camera_move_with_mouse(&state.camera, xpos, ypos)
}

scroll_callback :: proc "c" (window: glfw.WindowHandle, xoffset64: f64, yoffset64: f64) {
	state.camera.fov -= cast(f32)yoffset64

	if state.camera.fov < 1.0 {
		state.camera.fov = 1.0
	}
	if state.camera.fov > 90.0 {
		state.camera.fov = 90.0
	}
}

process_input :: proc(window: glfw.WindowHandle) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}

	camera_input(&state.camera, window)
}

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		temp_track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		mem.tracking_allocator_init(&temp_track, context.temp_allocator)
		context.allocator = mem.tracking_allocator(&track)
		context.temp_allocator = mem.tracking_allocator(&temp_track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}

		defer {
			if len(temp_track.allocation_map) > 0 {
				fmt.eprintf(
					"=== %v temp allocations not freed: ===\n",
					len(temp_track.allocation_map),
				)
				for _, entry in temp_track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&temp_track)
		}
	}

	glfw.Init()
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.RESIZABLE, glfw.FALSE)

	window := glfw.CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, WINDOW_TITLE, nil, nil)
	if window == nil {
		panic("failed to create window")
	}
	glfw.MakeContextCurrent(window)
	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)

	glfw.SetCursorPosCallback(window, mouse_callback)
	glfw.SetScrollCallback(window, scroll_callback)
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)

	// load opengl addresses
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)
	gl.Viewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

	// load texture
	first_image_width: i32 = ---
	first_image_height: i32 = ---
	second_image_width: i32 = ---
	second_image_height: i32 = ---
	nrChannels: i32 = ---

	first_image_data := stbi.load(
		"assets/container2.png",
		&first_image_width,
		&first_image_height,
		&nrChannels,
		0,
	)
	// stbi.set_flip_vertically_on_load(1)
	second_image_data := stbi.load(
		"assets/container2_specular.png",
		&second_image_width,
		&second_image_height,
		&nrChannels,
		0,
	)

	lightCubeShader, err := shader_create("assets/shaders/cube.vert", "assets/shaders/cube.frag")
	if err != nil {
		fmt.panicf("failed to compile shader: %s", err)
	}

	// delete it later
	defer shader_delete(&lightCubeShader)

	lightingShader, err2 := shader_create("assets/shaders/light.vert", "assets/shaders/light.frag")
	if err2 != nil {
		fmt.panicf("failed to compile lighting shader: %s", err2)
	}

	// delete it later
	defer shader_delete(&lightingShader)

	cubeVAO: u32 = --- // buffer for vertex attributes
	VBO: u32 = --- // buffer for vertices
	// EBO: u32 = --- // buffer for element order

	// Generate the buffers from the GPU
	gl.GenVertexArrays(1, &cubeVAO)
	gl.GenBuffers(1, &VBO)
	// gl.GenBuffers(1, &EBO)

	defer gl.DeleteVertexArrays(1, &cubeVAO)
	defer gl.DeleteBuffers(1, &VBO)
	// defer gl.DeleteBuffers(1, &EBO)

	// Send our vertices to the VAO
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)
	gl.BindVertexArray(cubeVAO)

	// Send our indices to the EBO
	// gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
	// gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)

	// Set the vertex attributes

	// position
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	// normal
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	// texture coords
	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 6 * size_of(f32))
	gl.EnableVertexAttribArray(2)

	// Make our light VAO
	lightCubeVAO: u32 = ---
	gl.GenVertexArrays(1, &lightCubeVAO)
	gl.BindVertexArray(lightCubeVAO)
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	// Initialize textures
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	texture1 := make_texture(first_image_width, first_image_height, gl.RGBA, first_image_data)
	texture2 := make_texture(second_image_width, second_image_height, gl.RGBA, second_image_data)

	// reset state
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	// set some flags up :)
	gl.Enable(gl.DEPTH_TEST)

	shader_use(&lightingShader)
	shader_set_int(&lightingShader, "material.diffuse", 0)
	shader_set_int(&lightingShader, "material.specular", 1)

	for !glfw.WindowShouldClose(window) {
		// free everything temporary
		free_all(context.temp_allocator)

		// update dt
		currentFrame := cast(f32)glfw.GetTime()
		state.deltaTime = currentFrame - state.lastFrame
		state.lastFrame = currentFrame

		state.lightPos.x = math.sin(currentFrame * 4) * 1.5
		state.lightPos.y = math.cos(currentFrame * 4) * 1.5
		state.lightPos.z = math.cos(currentFrame * 2) * 1.5

		process_input(window)

		// we render here!
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		shader_use(&lightingShader)
		shader_set_vec3(&lightingShader, "objectColor", glsl.vec3{1.0, 0.5, 0.31})
		shader_set_vec3(&lightingShader, "lightColor", glsl.vec3{1.0, 1.0, 1.0})

		view := camera_get_view(&state.camera)
		projection := camera_get_projection(&state.camera, SCREEN_WIDTH, SCREEN_HEIGHT)

		texture_use_slotted(&texture1, 0)
		texture_use_slotted(&texture2, 1)

		// MVP
		shader_set_mat4(&lightingShader, "view", view)
		shader_set_mat4(&lightingShader, "projection", projection)
		shader_set_vec3(&lightingShader, "viewPos", state.camera.pos)

		shader_set_float(&lightingShader, "material.shininess", 32.0)

		shader_set_vec3(&lightingShader, "light.direction", glsl.vec3{-0.2, -1.0, -0.3})
		shader_set_vec3(&lightingShader, "light.ambient", glsl.vec3{0.2, 0.2, 0.2})
		shader_set_vec3(&lightingShader, "light.diffuse", glsl.vec3{0.5, 0.5, 0.5})
		shader_set_vec3(&lightingShader, "light.specular", glsl.vec3{1.0, 1.0, 1.0})

		gl.BindVertexArray(cubeVAO)

		// OUR CUBES WITH LIGHTS!!!!!!! YAAAAAAAAY
		for i in 0 ..< 10 {
			model := glsl.mat4Translate(cubePositions[i])
			angle := 20.0 * cast(f32)i
			model *= glsl.mat4Rotate(glsl.vec3{1.0, 0.3, 0.5}, glsl.radians(angle))
			shader_set_mat4(&lightingShader, "model", model)
			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}

		// draw the tiny cube!

		shader_use(&lightCubeShader)

		// MVP
		shader_set_mat4(
			&lightCubeShader,
			"model",
			glsl.mat4Translate(state.lightPos) * glsl.mat4Scale(glsl.vec3(0.2)),
		)
		shader_set_mat4(&lightCubeShader, "view", view)
		shader_set_mat4(&lightCubeShader, "projection", projection)

		gl.BindVertexArray(lightCubeVAO)
		gl.DrawArrays(gl.TRIANGLES, 0, 36)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	free_all(context.temp_allocator)
}
