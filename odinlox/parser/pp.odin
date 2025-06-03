package parser

import "core:fmt"
import "core:strings"

// pretty-print AST

pp :: proc(ast: ^Expr, allocator := context.allocator) -> string {
	sb := strings.builder_make()
	format(&sb, ast)
	return strings.to_string(sb)
}

format :: proc(sb: ^strings.Builder, expr: ^Expr) {
	switch e in expr.variant {
	case ^Literal:
		fmt.sbprint(sb, e.value)
	case ^Unary:
		parenthesize(sb, e.operator.lexeme, e.right)
	case ^Binary:
		parenthesize(sb, e.operator.lexeme, e.left, e.right)
	case ^Grouping:
		parenthesize(sb, "grouping", e.content)
	}
}

parenthesize :: proc(sb: ^strings.Builder, name: string, exprs: ..^Expr) {
	fmt.sbprintf(sb, "(%s", name)

	for expr in exprs {
		strings.write_string(sb, " ")
		format(sb, expr)
	}
	strings.write_string(sb, ")")
}
