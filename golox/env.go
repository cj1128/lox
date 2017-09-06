package main

type Env map[string]Val

func (e Env) Define(name *Token, val Val) {
	e[name.lexeme] = val
}

func (e Env) Get(name *Token) Val {
	key := name.lexeme
	if e.has(key) {
		return e[key]
	}
	panic(NewRuntimeError(name, sprintf("undefined variable '%s'", key)))
}

func (e Env) Set(name *Token, val Val) {
	key := name.lexeme
	if e.has(key) {
		e[key] = val
		return
	}

	panic(NewRuntimeError(name, sprintf("undefined variable '%s'", key)))
}

func (e Env) has(key string) bool {
	_, ok := e[key]
	return ok
}
