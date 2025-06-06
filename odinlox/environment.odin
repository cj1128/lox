package lox

Env :: map[string]Value

define_var :: proc(e: ^Env, name: string, value: Value) {
	e[name] = value
}
