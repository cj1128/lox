package parser

import "core:fmt"
import "core:strings"

// pretty-print AST

pp :: proc(stmt: ^Stmt, allocator := context.allocator) -> string {
	sb := strings.builder_make()
	format_stmt(&sb, stmt)
	return strings.to_string(sb)
}

format_stmt :: proc(sb: ^strings.Builder, stmt: ^Stmt) {
	switch s in stmt.variant {
	case ^Print_Stmt:
		parenthesize(sb, "print-stmt", s.expr)

	case ^Expr_Stmt:
		parenthesize(sb, "expr-stmt", s.expr)

	case ^Var_Decl_Stmt:
		parenthesize_many(sb, {"var-decl-stmt", s.name.lexeme}, s.initializer)
	}
}

format_expr :: proc(sb: ^strings.Builder, expr: ^Expr) {
	switch e in expr.variant {
	case ^Literal_Expr:
		if str, ok := e.value.(string); ok {
			fmt.sbprintf(sb, "%q", str)
		} else {
			fmt.sbprint(sb, e.value)
		}
	case ^Unary_Expr:
		parenthesize(sb, e.operator.lexeme, e.right)

	case ^Binary_Expr:
		parenthesize(sb, e.operator.lexeme, e.left, e.right)

	case ^Ternary_Expr:
		parenthesize(sb, "?", e.condition, e.left, e.right)

	case ^Grouping_Expr:
		parenthesize(sb, "grouping", e.content)

	case ^Var_Expr:
		parenthesize_many(sb, {"var", e.name.lexeme})
	}
}

parenthesize_many :: proc(sb: ^strings.Builder, names: []string, exprs: ..^Expr) {
	fmt.sbprintf(sb, "(")
	for name, idx in names {
		if idx > 0 {
			strings.write_string(sb, " ")
		}
		fmt.sbprintf(sb, "%s", name)
	}

	for expr in exprs {
		if expr != nil {
			strings.write_string(sb, " ")
			format_expr(sb, expr)
		}
	}

	strings.write_string(sb, ")")
}

parenthesize :: proc(sb: ^strings.Builder, name: string, exprs: ..^Expr) {
	parenthesize_many(sb, {name}, ..exprs)
}
