package parser

Stmt :: struct {
	variant: union {
		^Expr_Stmt,
		^Print_Stmt,
		^Var_Decl_Stmt,
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
