package parser

import "../scanner"

Expr :: struct {
	variant: union {
		^Literal_Expr,
		^Unary_Expr,
		^Binary_Expr,
		^Grouping_Expr,
		^Ternary_Expr,
		^Var_Expr,
		^Assignment_Expr,
		^Logical_Expr,
	},
}

Literal_Expr :: struct {
	using expr: Expr,
	value:      scanner.Literal,
}
Unary_Expr :: struct {
	using expr: Expr,
	operator:   Token,
	right:      ^Expr,
}
Binary_Expr :: struct {
	using expr: Expr,
	operator:   Token,
	left:       ^Expr,
	right:      ^Expr,
}
Logical_Expr :: struct {
	using expr: Expr,
	operator:   Token,
	left:       ^Expr,
	right:      ^Expr,
}
Ternary_Expr :: struct {
	using expr: Expr,
	condition:  ^Expr,
	left:       ^Expr,
	right:      ^Expr,
}
Grouping_Expr :: struct {
	using expr: Expr,
	content:    ^Expr,
}
Var_Expr :: struct {
	using expr: Expr,
	name:       Token,
}
Assignment_Expr :: struct {
	using expr: Expr,
	name:       Token,
	value:      ^Expr,
}

new_expr :: proc($T: typeid) -> ^T {
	e := new(T)
	e.variant = e
	return e
}

new_literal_expr :: proc(value: scanner.Literal) -> ^Expr {
	result := new_expr(Literal_Expr)
	result.value = value
	return result
}

new_unary_expr :: proc(operator: Token, right: ^Expr) -> ^Expr {
	result := new_expr(Unary_Expr)
	result.operator = operator
	result.right = right
	return result
}

new_binary_expr :: proc(left: ^Expr, operator: Token, right: ^Expr) -> ^Expr {
	result := new_expr(Binary_Expr)
	result.left = left
	result.operator = operator
	result.right = right
	return result
}
new_logical_expr :: proc(left: ^Expr, operator: Token, right: ^Expr) -> ^Expr {
	result := new_expr(Logical_Expr)
	result.left = left
	result.operator = operator
	result.right = right
	return result
}

new_ternary_expr :: proc(condition, left, right: ^Expr) -> ^Expr {
	result := new_expr(Ternary_Expr)
	result.condition = condition
	result.left = left
	result.right = right
	return result
}

new_grouping_expr :: proc(expr: ^Expr) -> ^Expr {
	result := new_expr(Grouping_Expr)
	result.content = expr
	return result
}

new_var_expr :: proc(name: Token) -> ^Expr {
	result := new_expr(Var_Expr)
	result.name = name
	return result
}

new_assignment_expr :: proc(name: Token, value: ^Expr) -> ^Expr {
	result := new_expr(Assignment_Expr)
	result.name = name
	result.value = value
	return result
}
