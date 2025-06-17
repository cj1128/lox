package loxtw

import "base:runtime"
import "core:strings"

Env :: struct {
	m:         map[string]Value,
	enclosing: ^Env,
	global:    ^Env,
	allocator: runtime.Allocator,
	// used to track all envs (does not include global env), only global env has this field
	_envs:     [dynamic]^Env,
}

new_env :: proc(enclosing: ^Env = nil, allocator := context.allocator) -> ^Env {
	env := new(Env, allocator)
	env.m = make(map[string]Value, allocator)
	env.enclosing = enclosing

	if enclosing == nil {
		env.global = env
		env._envs = make([dynamic]^Env, allocator)
		env.allocator = allocator
	} else {
		env.global = enclosing.global
		env.allocator = enclosing.allocator
		append(&env.global._envs, env)
	}

	return env
}

destroy_env :: proc(env: ^Env) {
	// sub envs
	for env in env.global._envs {
		for key in env.m {
			delete(key)
		}
		delete(env.m)
		free(env)
	}

	// global env
	g := env.global
	delete(g.m)
	delete(g._envs)
	free(g)
}

env_define :: proc(e: ^Env, name: string, value: Value) {
	e.m[strings.clone(name)] = value
}

env_lookup :: proc(e: ^Env, name: string) -> (value: Value, exists: bool) {
	result, ok := e.m[name]

	if !ok && e.enclosing != nil {
		return env_lookup(e.enclosing, name)
	}

	return result, ok
}

env_assign :: proc(e: ^Env, name: string, value: Value) -> bool {
	_, ok := e.m[name]
	if ok {
		e.m[name] = value
		return true
	}

	if e.enclosing != nil {
		return env_assign(e.enclosing, name, value)
	}

	return false
}
