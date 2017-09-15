package main

type Env struct {
	prev *Env
	m    map[string]Val
}

func NewEnv(prev *Env) *Env {
	return &Env{
		prev,
		map[string]Val{},
	}
}

func (e *Env) Define(name string, val Val) {
	e.m[name] = val
}

func (e *Env) Get(name *Token) Val {
	key := name.lexeme
	if e.has(key) {
		return e.m[key]
	}

	if e.prev != nil {
		return e.prev.Get(name)
	}

	panic(NewRuntimeError(name, sprintf("undefined variable '%s'", key)))
}

func (e Env) Set(name *Token, val Val) {
	key := name.lexeme

	if e.has(key) {
		e.m[key] = val
		return
	}

	if e.prev != nil {
		e.prev.Set(name, val)
		return
	}

	panic(NewRuntimeError(name, sprintf("undefined variable '%s'", key)))
}

func (e Env) has(key string) bool {
	_, ok := e.m[key]
	return ok
}
