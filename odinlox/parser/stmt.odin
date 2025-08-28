package parser

Stmt :: struct {
	variant: union {
		^Expr_Stmt,
		^Print_Stmt,
		^Var_Decl_Stmt,
		^Block_Stmt,
		^If_Stmt,
		^While_Stmt,
		^Function_Decl_Stmt,
		^Class_Decl_Stmt,
		^Return_Stmt,
	},
}

Expr_Stmt :: struct {
	using stmt: Stmt,
	expr:       ^Expr,
}
Print_Stmt :: struct {
	using stmt: Stmt,
	expr:       ^Expr,
}
Var_Decl_Stmt :: struct {
	using stmt:  Stmt,
	name:        Token,
	initializer: ^Expr,
}
Block_Stmt :: struct {
	using stmt: Stmt,
	stmts:      []^Stmt,
}
If_Stmt :: struct {
	using stmt:  Stmt,
	condition:   ^Expr,
	then_branch: ^Stmt,
	else_branch: ^Stmt, // may be nil
}
While_Stmt :: struct {
	using stmt: Stmt,
	condition:  ^Expr,
	body:       ^Stmt,
}
Function_Decl_Stmt :: struct {
	using stmt: Stmt,
	name:       Token,
	params:     []Token,
	body:       []^Stmt,
}
Class_Decl_Stmt :: struct {
	using stmt: Stmt,
	name:       Token,
	methods:    []^Function_Decl_Stmt,
}
// keeps the `return` keyword token so we can use its location for error reporting
Return_Stmt :: struct {
	using stmt: Stmt,
	keyword:    Token,
	// maybe nil
	value:      ^Expr,
}

new_stmt :: proc($T: typeid) -> ^T {
	e := new(T)
	e.variant = e
	return e
}

new_print_stmt :: proc(expr: ^Expr) -> ^Stmt {
	result := new_stmt(Print_Stmt)
	result.expr = expr
	return result
}

new_expr_stmt :: proc(expr: ^Expr) -> ^Stmt {
	result := new_stmt(Expr_Stmt)
	result.expr = expr
	return result
}

new_var_decl_stmt :: proc(name: Token, initializer: ^Expr) -> ^Stmt {
	result := new_stmt(Var_Decl_Stmt)
	result.name = name
	result.initializer = initializer
	return result
}

new_block_stmt :: proc(stmts: []^Stmt) -> ^Stmt {
	result := new_stmt(Block_Stmt)
	result.stmts = stmts
	return result
}

new_if_stmt :: proc(condition: ^Expr, then_branch, else_branch: ^Stmt) -> ^Stmt {
	result := new_stmt(If_Stmt)
	result.condition = condition
	result.then_branch = then_branch
	result.else_branch = else_branch
	return result
}

new_while_stmt :: proc(condition: ^Expr, body: ^Stmt) -> ^Stmt {
	result := new_stmt(While_Stmt)
	result.condition = condition
	result.body = body
	return result
}

new_function_decl_stmt :: proc(name: Token, params: []Token, body: []^Stmt) -> ^Stmt {
	result := new_stmt(Function_Decl_Stmt)
	result.name = name
	result.params = params
	result.body = body
	return result
}

new_class_decl_stmt :: proc(name: Token, methods: []^Function_Decl_Stmt) -> ^Stmt {
	result := new_stmt(Class_Decl_Stmt)
	result.name = name
	result.methods = methods
	return result
}

new_return_stmt :: proc(keyword: Token, value: ^Expr) -> ^Stmt {
	result := new_stmt(Return_Stmt)
	result.keyword = keyword
	result.value = value
	return result
}
