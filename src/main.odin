package main

import "base:runtime"
import "core:fmt"
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
}

state := GameState {
	deltaTime  = 0.0,
	lastFrame  = 0.0,
	firstMouse = true,
	lastMouseX = cast(f32)SCREEN_WIDTH / 2.0,
	lastMouseY = cast(f32)SCREEN_HEIGHT / 2.0,
	camera     = DEFAULT_CAMERA,
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
		"assets/container.jpg",
		&first_image_width,
		&first_image_height,
		&nrChannels,
		0,
	)
	stbi.set_flip_vertically_on_load(1)
	second_image_data := stbi.load(
		"assets/awesomeface.png",
		&second_image_width,
		&second_image_height,
		&nrChannels,
		0,
	)

	shader, err := shader_create("assets/vert.vert", "assets/frag.frag")
	if err != nil {
		fmt.panicf("failed to compile shader: %s", err)
	}

	// delete it later
	defer shader_delete(&shader)

	VAO: u32 = --- // buffer for vertex attributes
	VBO: u32 = --- // buffer for vertices
	// EBO: u32 = --- // buffer for element order

	// Generate the buffers from the GPU
	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	// gl.GenBuffers(1, &EBO)

	defer gl.DeleteVertexArrays(1, &VAO)
	defer gl.DeleteBuffers(1, &VBO)
	// defer gl.DeleteBuffers(1, &EBO)

	// Send our vertices to the VAO
	gl.BindVertexArray(VAO)
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	// Send our indices to the EBO
	// gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
	// gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)

	// Set the vertex attributes

	// position
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	// texture coords
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	// Initialize textures
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRRORED_REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	texture1 := make_texture(first_image_width, first_image_height, gl.RGB, first_image_data)
	texture2 := make_texture(second_image_width, second_image_height, gl.RGBA, second_image_data)

	// reset state
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	// set some flags up :)
	gl.Enable(gl.DEPTH_TEST)

	for !glfw.WindowShouldClose(window) {
		// free everything temporary
		free_all(context.temp_allocator)

		// update dt
		currentFrame := cast(f32)glfw.GetTime()
		state.deltaTime = currentFrame - state.lastFrame
		state.lastFrame = currentFrame

		process_input(window)

		// we render here!
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		texture_use_slotted(&texture1, 0)
		texture_use_slotted(&texture2, 1)

		gl.BindVertexArray(VAO)

		shader_use(&shader)
		shader_set_int(&shader, "texture1", 0)
		shader_set_int(&shader, "texture2", 1)

		// model := camera_get_model()
		view := camera_get_view(&state.camera)
		projection := camera_get_projection(&state.camera, SCREEN_WIDTH, SCREEN_HEIGHT)

		shader_set_mat4(&shader, "view", view)
		shader_set_mat4(&shader, "projection", projection)

		for i in 0 ..< 10 {
			model :=
				glsl.mat4Translate(cube_positions[i]) *
				glsl.mat4Rotate(glsl.vec3{1.0, 0.3, 0.5}, glsl.radians_f32(f32(20.0 * i)))
			shader_set_mat4(&shader, "model", model)
			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	free_all(context.temp_allocator)
}
