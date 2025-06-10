package parser

import "core:fmt"
import "core:strings"

// pretty-print AST

pp :: proc(stmt: ^Stmt, allocator := context.allocator) -> string {
	sb := strings.builder_make(allocator)
	format_stmt(&sb, stmt)
	return strings.to_string(sb)
}

pp_expr :: proc(expr: ^Expr, allocator := context.allocator) -> string {
	sb := strings.builder_make(allocator)
	format_expr(&sb, expr)
	return strings.to_string(sb)
}

format_stmt :: proc(sb: ^strings.Builder, stmt: ^Stmt) {
	switch s in stmt.variant {
	case ^Block_Stmt:
		p_stmt(sb, "block-stmt", ..s.stmts)

	case ^Print_Stmt:
		p_expr(sb, "print-stmt", s.expr)

	case ^Expr_Stmt:
		p_expr(sb, "expr-stmt", s.expr)

	case ^Var_Decl_Stmt:
		p_m_expr(sb, {"var-decl-stmt", s.name.lexeme}, s.initializer)
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
		p_expr(sb, e.operator.lexeme, e.right)

	case ^Assignment_Expr:
		p_m_expr(sb, {"=", e.name.lexeme}, e.value)

	case ^Binary_Expr:
		p_expr(sb, e.operator.lexeme, e.left, e.right)

	case ^Ternary_Expr:
		p_expr(sb, "?", e.condition, e.left, e.right)

	case ^Grouping_Expr:
		p_expr(sb, "grouping", e.content)

	case ^Var_Expr:
		p_m_expr(sb, {"var", e.name.lexeme})
	}
}

p_m_stmt :: proc(sb: ^strings.Builder, names: []string, stmts: ..^Stmt) {
	fmt.sbprintf(sb, "(")
	for name, idx in names {
		if idx > 0 {
			strings.write_string(sb, " ")
		}
		fmt.sbprintf(sb, "%s", name)
	}

	for stmt in stmts {
		if stmt != nil {
			strings.write_string(sb, " ")
			format_stmt(sb, stmt)
		}
	}

	strings.write_string(sb, ")")
}
p_stmt :: proc(sb: ^strings.Builder, name: string, stmts: ..^Stmt) {
	p_m_stmt(sb, {name}, ..stmts)
}

p_m_expr :: proc(sb: ^strings.Builder, names: []string, exprs: ..^Expr) {
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

p_expr :: proc(sb: ^strings.Builder, name: string, exprs: ..^Expr) {
	p_m_expr(sb, {name}, ..exprs)
}
