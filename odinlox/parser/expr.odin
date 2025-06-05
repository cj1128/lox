package parser

import "../scanner"

Expr :: struct {
	variant: union {
		^Literal,
		^Unary,
		^Binary,
		^Grouping,
		^Ternary,
	},
}

Literal :: struct {
	using expr: Expr,
	value:      scanner.Literal,
}
Unary :: struct {
	using expr: Expr,
	operator:   Token,
	right:      ^Expr,
}
Binary :: struct {
	using expr: Expr,
	operator:   Token,
	left:       ^Expr,
	right:      ^Expr,
}
Ternary :: struct {
	using expr: Expr,
	condition:  ^Expr,
	left:       ^Expr,
	right:      ^Expr,
}
Grouping :: struct {
	using expr: Expr,
	content:    ^Expr,
}

new_expr :: proc($T: typeid) -> ^T {
	e := new(T)
	e.variant = e
	return e
}

literal_expr :: proc(value: scanner.Literal) -> ^Expr {
	result := new_expr(Literal)
	result.value = value
	return result
}

unary_expr :: proc(operator: Token, right: ^Expr) -> ^Expr {
	result := new_expr(Unary)
	result.operator = operator
	result.right = right
	return result
}

binary_expr :: proc(left: ^Expr, operator: Token, right: ^Expr) -> ^Expr {
	result := new_expr(Binary)
	result.left = left
	result.operator = operator
	result.right = right
	return result
}

ternary_expr :: proc(condition, left, right: ^Expr) -> ^Expr {
	result := new_expr(Ternary)
	result.condition = condition
	result.left = left
	result.right = right
	return result
}

grouping_expr :: proc(expr: ^Expr) -> ^Expr {
	result := new_expr(Grouping)
	result.content = expr
	return result
}
