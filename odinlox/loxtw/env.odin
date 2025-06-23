package loxtw

import "base:runtime"
import "core:strings"

Env :: struct {
	m:         map[string]Value,
	enclosing: ^Env,
	global:    ^Env,
	locals:    map[^Expr]int,
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

_get_env :: proc(e: ^Env, expr: ^Expr) -> ^Env {
	distance, ok := e.global.locals[expr]
	if !ok {
		return e.global
	}

	result := e
	for _ in 0 ..< distance {
		result = result.enclosing
	}

	return result
}

env_lookup :: proc(e: ^Env, expr: ^Var_Expr) -> (value: Value, exists: bool) {
	target_env := _get_env(e, expr)

	return target_env.m[expr.name.lexeme]
}

// return false is var not found
env_assign :: proc(e: ^Env, expr: ^Assignment_Expr, value: Value) -> bool {
	target_env := _get_env(e, expr)

	name := expr.name.lexeme

	_, ok := target_env.m[name]
	if !ok {
		return false
	}

	target_env.m[name] = value
	return true
}
