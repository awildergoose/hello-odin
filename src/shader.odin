package main

import "core:c"
import "core:fmt"
import "core:math/linalg/glsl"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"

Shader :: struct {
	id: u32,
}

@(private)
gl_check_shader_compilation :: proc(id: u32) {
	success: i32
	infoLog: [512]c.char
	gl.GetShaderiv(id, gl.COMPILE_STATUS, &success)

	if success == 0 {
		gl.GetShaderInfoLog(id, 512, nil, raw_data(&infoLog))
		fmt.panicf("Failed to compile shader:\n%s", infoLog)
	}
}

@(private)
gl_check_program_linkage :: proc(id: u32) {
	success: i32
	infoLog: [512]c.char

	gl.GetProgramiv(id, gl.LINK_STATUS, &success)

	if success == 0 {
		gl.GetProgramInfoLog(id, 512, nil, raw_data(&infoLog))
		fmt.panicf("Failed to link shader program:\n%s", infoLog)
	}
}

shader_create :: proc(
	vertex_path: string,
	fragment_path: string,
) -> (
	shader: Shader,
	err: os.Error,
) {
	vs_str := os.read_entire_file_from_path(vertex_path, context.temp_allocator) or_return
	fs_str := os.read_entire_file_from_path(fragment_path, context.temp_allocator) or_return

	vertex := strings.clone_to_cstring(string(vs_str), context.temp_allocator)
	fragment := strings.clone_to_cstring(string(fs_str), context.temp_allocator)

	// vertex shader
	vs: u32 = gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(vs, 1, &vertex, nil)
	gl.CompileShader(vs)

	// check if it compiled properly!
	gl_check_shader_compilation(vs)

	// fragment shader
	fs: u32 = gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(fs, 1, &fragment, nil)
	gl.CompileShader(fs)

	// check if it compiled properly!
	gl_check_shader_compilation(fs)

	// create the shader program
	program: u32 = gl.CreateProgram()
	gl.AttachShader(program, vs)
	gl.AttachShader(program, fs)
	gl.LinkProgram(program)

	// check if it linked properly!
	gl_check_program_linkage(program)

	// we don't need these anymore!
	gl.DeleteShader(vs)
	gl.DeleteShader(fs)

	return Shader{id = program}, nil
}

shader_use :: proc(shader: ^Shader) {
	gl.UseProgram(shader.id)
}

shader_delete :: proc(shader: ^Shader) {
	gl.DeleteProgram(shader.id)
}

shader_get_location := proc(shader: ^Shader, name: string) -> i32 {
	return gl.GetUniformLocation(shader.id, strings.clone_to_cstring(name, context.temp_allocator))
}

shader_set_bool := proc(shader: ^Shader, name: string, value: bool) {
	gl.Uniform1i(shader_get_location(shader, name), cast(i32)value)
}

shader_set_int := proc(shader: ^Shader, name: string, value: i32) {
	gl.Uniform1i(shader_get_location(shader, name), value)
}

shader_set_uint := proc(shader: ^Shader, name: string, value: u32) {
	gl.Uniform1ui(shader_get_location(shader, name), value)
}

shader_set_float := proc(shader: ^Shader, name: string, value: f32) {
	gl.Uniform1f(shader_get_location(shader, name), value)
}

shader_set_mat4 := proc(shader: ^Shader, name: string, value: glsl.mat4) {
	value := value
	gl.UniformMatrix4fv(shader_get_location(shader, name), 1, gl.FALSE, raw_data(&value))
}

shader_set_vec3 := proc(shader: ^Shader, name: string, value: glsl.vec3) {
	value := value
	gl.Uniform3fv(shader_get_location(shader, name), 1, raw_data(&value))
}
