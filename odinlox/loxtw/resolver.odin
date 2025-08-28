package loxtw

import parser "../parser"
import "core:fmt"

Var_Status :: enum {
	Not_Exist,
	Initializing,
	Initialized,
}

Var_Scope :: map[string]Var_Status

Function_Type :: parser.Function_Type

Resolver :: struct {
	result:           ^Resolve_Result,
	scopes:           [dynamic]Var_Scope,
	current_function: Function_Type,
}

Resolve_Error :: union {
	Local_Variable_Self_Initialization_Error,
	Local_Variable_Already_Defined,
	Invalid_Return,
}

Local_Variable_Self_Initialization_Error :: struct {}
Local_Variable_Already_Defined :: struct {}
Invalid_Return :: struct {}

Resolve_Result :: struct {
	locals: map[^Expr]int,
	errors: [dynamic]Resolve_Error,
}

resolve :: proc(program: []^Stmt, allocator := context.allocator) -> ^Resolve_Result {
	result := new(Resolve_Result, allocator)
	resolver := &Resolver{result = result}

	resolve_stmts(resolver, program)
	delete(resolver.scopes)

	return result
}

resolve_stmts :: proc(r: ^Resolver, stmts: []^Stmt) {
	for stmt in stmts {
		resolve_stmt(r, stmt)
	}
}

resolve_stmt :: proc(r: ^Resolver, stmt: ^Stmt) {
	switch s in stmt.variant {
	case ^Block_Stmt:
		begin_scope(r)
		resolve_stmts(r, s.stmts)
		end_scope(r)
	case ^Var_Decl_Stmt:
		declare(r, s.name)
		if s.initializer != nil {
			resolve_expr(r, s.initializer)
		}
		define(r, s.name)
	case ^Function_Decl_Stmt:
		define(r, s.name)
		resolve_function(r, s, .Function)
	case ^Class_Decl_Stmt:
		define(r, s.name)
	case ^Expr_Stmt:
		resolve_expr(r, s.expr)
	case ^If_Stmt:
		resolve_expr(r, s.condition)
		resolve_stmt(r, s.then_branch)
		if s.else_branch != nil {
			resolve_stmt(r, s.else_branch)
		}
	case ^Print_Stmt:
		resolve_expr(r, s.expr)
	case ^While_Stmt:
		resolve_expr(r, s.condition)
		resolve_stmt(r, s.body)
	case ^Return_Stmt:
		if r.current_function == .None {
			append(&r.result.errors, Invalid_Return{})
		}
		resolve_expr(r, s.value)
	}
}

resolve_expr :: proc(r: ^Resolver, expr: ^Expr) {
	switch e in expr.variant {
	case ^Var_Expr:
		if cur_scope_get(r, e.name.lexeme) == .Initializing {
			append(&r.result.errors, Local_Variable_Self_Initialization_Error{})
		}
		resolve_local(r, e, e.name)
	case ^Assignment_Expr:
		resolve_expr(r, e.value)
		resolve_local(r, e, e.name)
	case ^Binary_Expr:
		resolve_expr(r, e.left)
		resolve_expr(r, e.right)
	case ^Call_Expr:
		resolve_expr(r, e.callee)
		for arg in e.arguments {
			resolve_expr(r, arg)
		}
	case ^Grouping_Expr:
		resolve_expr(r, e.content)
	case ^Literal_Expr:
	// nothing to do
	case ^Logical_Expr:
		resolve_expr(r, e.left)
		resolve_expr(r, e.right)
	case ^Unary_Expr:
		resolve_expr(r, e.right)
	case ^Ternary_Expr:
		resolve_expr(r, e.condition)
		resolve_expr(r, e.left)
		resolve_expr(r, e.right)
	}
}

resolve_function :: proc(r: ^Resolver, stmt: ^Function_Decl_Stmt, type: Function_Type) {
	prev_type := r.current_function
	r.current_function = type

	begin_scope(r)
	for param in stmt.params {
		define(r, param)
	}
	resolve_stmts(r, stmt.body)
	end_scope(r)

	r.current_function = prev_type
}

resolve_local :: proc(r: ^Resolver, expr: ^Expr, name: Token) {
	L := len(r.scopes)
	#reverse for scope, idx in r.scopes {
		if _, ok := scope[name.lexeme]; ok {
			r.result.locals[expr] = L - 1 - idx
		}
	}
}

declare :: proc(r: ^Resolver, name: Token) {
	_inner_scope_set(r, name.lexeme, .Initializing)
}
define :: proc(r: ^Resolver, name: Token) {
	_inner_scope_set(r, name.lexeme, .Initialized)
}

begin_scope :: proc(r: ^Resolver) {
	append(&r.scopes, make(Var_Scope))
}
end_scope :: proc(r: ^Resolver) {
	idx := len(r.scopes) - 1
	unordered_remove(&r.scopes, idx)
}

_inner_scope_set :: proc(r: ^Resolver, name: string, value: Var_Status) {
	if len(r.scopes) == 0 {
		return
	}

	if r.scopes[len(r.scopes) - 1][name] == .Initialized {
		append(&r.result.errors, Local_Variable_Already_Defined{})
	}

	r.scopes[len(r.scopes) - 1][name] = value
}
cur_scope_get :: proc(r: ^Resolver, name: string) -> Var_Status {
	if len(r.scopes) == 0 {
		return .Not_Exist
	}
	return r.scopes[len(r.scopes) - 1][name]
}
