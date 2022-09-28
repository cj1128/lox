package main

type Callable interface {
	Call(env *Env, arguments []Val) Val
	Arity() int
}

type Function struct {
	arity    int
	function func(*Env, []Val) Val
}

func NewFunction(arity int, function func(*Env, []Val) Val) *Function {
	return &Function{arity, function}
}

func (f *Function) Arity() int {
	return f.arity
}

func (f *Function) Call(env *Env, arguments []Val) Val {
	return f.function(env, arguments)
}

/*----------  Lox Function  ----------*/

func (s *StmtFuncDecl) Arity() int {
	return len(s.parameters)
}

func (s *StmtFuncDecl) Call(_env *Env, arguments []Val) (result Val) {
	newEnv := NewEnv(s.closure)
	for i, arg := range arguments {
		name := s.parameters[i].Lexeme
		newEnv.Define(name, arg)
	}

	// handle function return
	defer func() {
		if err := recover(); err != nil {
			if fr, ok := err.(*FunctionReturn); ok {
				result = fr.value
			} else {
				panic(err)
			}
		}
	}()

	for _, stmt := range s.body {
		stmt.Run(newEnv)
	}

	return nil
}
