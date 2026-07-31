package main

import "base:runtime"
import "core:fmt"
import "core:math/linalg/glsl"

@(require) import "core:mem"

import gl "vendor:OpenGL"
import "vendor:glfw"
import stbi "vendor:stb/image"

GameState :: struct {
	deltaTime:         f32,
	lastFrame:         f32,
	firstMouse:        bool,
	lastMouseX:        f32,
	lastMouseY:        f32,
	camera:            Camera,
	directionalLights: [dynamic]DirectionalLight,
	pointLights:       [dynamic]PointLight,
	spotLights:        [dynamic]SpotLight,
}

state := GameState {
	deltaTime         = 0.0,
	lastFrame         = 0.0,
	firstMouse        = true,
	lastMouseX        = cast(f32)SCREEN_WIDTH / 2.0,
	lastMouseY        = cast(f32)SCREEN_HEIGHT / 2.0,
	camera            = DEFAULT_CAMERA,
	directionalLights = {},
	pointLights       = {},
	spotLights        = {},
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
	diffuse_width: i32 = ---
	diffuse_height: i32 = ---
	specular_width: i32 = ---
	specular_height: i32 = ---
	nrChannels: i32 = ---

	diffuse_data := stbi.load(
		"assets/container2.png",
		&diffuse_width,
		&diffuse_height,
		&nrChannels,
		0,
	)
	// stbi.set_flip_vertically_on_load(1)
	specular_data := stbi.load(
		"assets/container2_specular.png",
		&specular_width,
		&specular_height,
		&nrChannels,
		0,
	)

	shadedObjectShader, err := shader_create(
		"assets/shaders/light.vert",
		"assets/shaders/light.frag",
	)
	if err != nil {
		fmt.panicf("failed to compile lighting shader: %s", err)
	}

	// delete it later
	defer shader_delete(&shadedObjectShader)

	VAO: u32 = --- // buffer for vertex attributes
	VBO: u32 = --- // buffer for vertices

	// Generate the buffers from the GPU
	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)

	defer gl.DeleteVertexArrays(1, &VAO)
	defer gl.DeleteBuffers(1, &VBO)

	// Send our vertices to the VAO
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)
	gl.BindVertexArray(VAO)

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

	// Initialize textures
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	diffuse_tex := make_texture(diffuse_width, diffuse_height, gl.RGBA, diffuse_data)
	specular_tex := make_texture(specular_width, specular_height, gl.RGBA, specular_data)

	// initialize our 3 SSBOs for lighting
	directionalSSBO: u32 = ---
	gl.GenBuffers(1, &directionalSSBO)
	defer gl.DeleteBuffers(1, &directionalSSBO)

	pointSSBO: u32 = ---
	gl.GenBuffers(1, &pointSSBO)
	defer gl.DeleteBuffers(1, &pointSSBO)

	spotSSBO: u32 = ---
	gl.GenBuffers(1, &spotSSBO)
	defer gl.DeleteBuffers(1, &spotSSBO)

	// reset state
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	// set some flags up :)
	gl.Enable(gl.DEPTH_TEST)

	shader_use(&shadedObjectShader)
	shader_set_int(&shadedObjectShader, "material.diffuse", 0)
	shader_set_int(&shadedObjectShader, "material.specular", 1)

	append(
		&state.directionalLights,
		make_directional_light(
			glsl.vec3(0.0),
			glsl.vec3(0.05),
			glsl.vec3(0.2),
			glsl.vec3{-0.2, -1.0, -0.3},
		),
	)

	append(
		&state.pointLights,
		make_point_light(
			pointLightPositions[0],
			pointLightColors[0] * 0.1,
			pointLightColors[0],
			pointLightColors[0],
			1.0,
			0.14,
			0.07,
		),
	)

	append(
		&state.pointLights,
		make_point_light(
			pointLightPositions[1],
			pointLightColors[1] * 0.1,
			pointLightColors[1],
			pointLightColors[1],
			1.0,
			0.14,
			0.07,
		),
	)

	append(
		&state.pointLights,
		make_point_light(
			pointLightPositions[2],
			pointLightColors[2] * 0.1,
			pointLightColors[2],
			pointLightColors[2],
			1.0,
			0.22,
			0.20,
		),
	)

	append(
		&state.pointLights,
		make_point_light(
			pointLightPositions[3],
			pointLightColors[3] * 0.1,
			pointLightColors[3],
			pointLightColors[3],
			1.0,
			0.14,
			0.07,
		),
	)

	flashlight := append(
		&state.spotLights,
		make_spot_light(
			state.camera.pos,
			glsl.vec3(0.0),
			glsl.vec3(1.0),
			glsl.vec3(1.0),
			1.0,
			0.09,
			0.032,
			state.camera.front,
			glsl.cos_f32(glsl.radians_f32(10.0)),
			glsl.cos_f32(glsl.radians_f32(15.0)),
		),
	)
	flashlight -= 1

	defer delete(state.directionalLights)
	defer delete(state.spotLights)
	defer delete(state.pointLights)

	// this can probably fit a lot
	std430 := make_std430(32768)
	defer std430_clear(&std430)

	for !glfw.WindowShouldClose(window) {
		// free everything temporary
		free_all(context.temp_allocator)

		// clear the std430 builder buffer
		std430_clear(&std430)

		// update dt
		currentFrame := cast(f32)glfw.GetTime()
		state.deltaTime = currentFrame - state.lastFrame
		state.lastFrame = currentFrame

		process_input(window)

		// we render here!
		gl.ClearColor(0.0, 0.0, 0.0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		shader_use(&shadedObjectShader)

		view := camera_get_view(&state.camera)
		projection := camera_get_projection(&state.camera, SCREEN_WIDTH, SCREEN_HEIGHT)

		texture_use_slotted(&diffuse_tex, 0)
		texture_use_slotted(&specular_tex, 1)

		// MVP
		shader_set_mat4(&shadedObjectShader, "view", view)
		shader_set_mat4(&shadedObjectShader, "projection", projection)

		shader_set_vec3(&shadedObjectShader, "viewPos", state.camera.pos)
		shader_set_float(&shadedObjectShader, "material.shininess", 32.0)
		shader_set_float(&shadedObjectShader, "time", currentFrame)

		shader_set_uint(&shadedObjectShader, "dCount", cast(u32)len(&state.directionalLights))
		shader_set_uint(&shadedObjectShader, "pCount", cast(u32)len(&state.pointLights))
		shader_set_uint(&shadedObjectShader, "sCount", cast(u32)len(&state.spotLights))

		state.spotLights[flashlight].position = state.camera.pos
		state.spotLights[flashlight].direction = state.camera.front

		for &light in state.directionalLights {
			encode_directional_light(&std430, &light)
		}

		gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, directionalSSBO)
		gl.BufferData(
			gl.SHADER_STORAGE_BUFFER,
			std430.offset,
			raw_data(std430.data[:std430.offset]),
			gl.DYNAMIC_DRAW,
		)
		gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, directionalSSBO)

		std430_clear(&std430)

		for &light in state.pointLights {
			encode_point_light(&std430, &light)
		}

		gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, pointSSBO)
		gl.BufferData(
			gl.SHADER_STORAGE_BUFFER,
			std430.offset,
			raw_data(std430.data[:std430.offset]),
			gl.DYNAMIC_DRAW,
		)
		gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 2, pointSSBO)

		std430_clear(&std430)

		for &light in state.spotLights {
			encode_spot_light(&std430, &light)
		}

		gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, spotSSBO)
		gl.BufferData(
			gl.SHADER_STORAGE_BUFFER,
			std430.offset,
			raw_data(std430.data[:std430.offset]),
			gl.DYNAMIC_DRAW,
		)
		gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 3, spotSSBO)

		gl.BindVertexArray(VAO)

		// OUR CUBES WITH LIGHTS!!!!!!! YAAAAAAAAY
		for i in 0 ..< 10 {
			model := glsl.mat4Translate(cubePositions[i])
			angle := 20.0 * cast(f32)i
			model *= glsl.mat4Rotate(glsl.vec3{1.0, 0.3, 0.5}, glsl.radians(angle))
			shader_set_mat4(&shadedObjectShader, "model", model)
			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	free_all(context.temp_allocator)
}
