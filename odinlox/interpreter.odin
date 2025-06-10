package lox

import "./parser"
import "./scanner"
import "core:fmt"
import "core:strings"

Token :: scanner.Token
Value :: scanner.Literal

Stmt :: parser.Stmt
Expr_Stmt :: parser.Expr_Stmt
Print_Stmt :: parser.Print_Stmt
Var_Decl_Stmt :: parser.Var_Decl_Stmt
Block_Stmt :: parser.Block_Stmt
If_Stmt :: parser.If_Stmt

Expr :: parser.Expr
Literal :: parser.Literal_Expr
Binary :: parser.Binary_Expr
Unary :: parser.Unary_Expr
Grouping :: parser.Grouping_Expr
Ternary :: parser.Ternary_Expr
Var_Expr :: parser.Var_Expr
Assignment_Expr :: parser.Assignment_Expr
Logical_Expr :: parser.Logical_Expr

Evaluate_Error :: union {
	Must_Be_Two_Numbers_Or_Two_Strings,
	Must_Be_A_Number,
	Must_Be_Numbers,
	Undefined_Var,
}
Must_Be_Two_Numbers_Or_Two_Strings :: struct {
	operator: Token,
}
Must_Be_A_Number :: struct {
	operator: Token,
}
Must_Be_Numbers :: struct {
	operator: Token,
}
Undefined_Var :: struct {
	var: Token,
}

evaluate :: proc(env: ^Env, stmt: ^Stmt) -> Evaluate_Error {
	switch s in stmt.variant {
	case ^If_Stmt:
		cond := evaluate_expr(env, s.condition) or_return
		if is_truthy(cond) {
			evaluate(env, s.then_branch) or_return
		} else if s.else_branch != nil {
			evaluate(env, s.then_branch) or_return
		}

	case ^Block_Stmt:
		sub_env := new_env(env)
		for stmt in s.stmts {
			evaluate(sub_env, stmt) or_return
		}

	case ^Print_Stmt:
		value := evaluate_expr(env, s.expr) or_return
		fmt.println(value)

	case ^Expr_Stmt:
		evaluate_expr(env, s.expr) or_return

	case ^Var_Decl_Stmt:
		value: Value
		if s.initializer != nil {
			value = evaluate_expr(env, s.initializer) or_return
		}
		env_define_var(env, s.name.lexeme, value)
	}

	return nil
}

evaluate_expr :: proc(env: ^Env, expr: ^Expr) -> (result: Value, err: Evaluate_Error) {
	switch e in expr.variant {

	case ^Logical_Expr:
		left := evaluate_expr(env, e.left) or_return

		if e.operator.type == .OR {
			if is_truthy(left) {
				return left, nil
			}
		} else {
			if !is_truthy(left) {
				return left, nil
			}
		}

		return evaluate_expr(env, e.right)

	case ^Var_Expr:
		val, ok := env_lookup_var(env, e.name.lexeme)
		if !ok {
			return nil, Undefined_Var{var = e.name}
		}
		return val, nil

	case ^Assignment_Expr:
		value := evaluate_expr(env, e.value) or_return
		ok := env_assign_var(env, e.name.lexeme, value)

		if !ok {
			return nil, Undefined_Var{var = e.name}
		}

		return value, nil

	case ^Literal:
		result = e.value

	case ^Unary:
		v := evaluate_expr(env, e.right) or_return

		#partial switch e.operator.type {
		case .BANG:
			result = !is_truthy(v)

		case .MINUS:
			if !is_number(v) {
				return nil, Must_Be_A_Number{operator = e.operator}
			}
			result = -v.(f64)

		case:
			panic("unreachable")
		}

	case ^Binary:
		left := evaluate_expr(env, e.left) or_return
		right := evaluate_expr(env, e.right) or_return

		#partial switch e.operator.type {
		case .EQUAL_EQUAL:
			result = left == right
			return

		case .BANG_EQUAL:
			result = left != right
			return

		case .COMMA:
			return right, nil

		case .PLUS:
			if is_number(left) && is_number(right) {
				result = left.(f64) + right.(f64)
			} else if is_string(left) && is_string(right) {
				result = fmt.tprintf("%s%s", left.(string), right.(string))
			} else {
				err = Must_Be_Two_Numbers_Or_Two_Strings {
					operator = e.operator,
				}
			}
			return
		}

		if !is_number(left) || !is_number(right) {
			err = Must_Be_Numbers {
				operator = e.operator,
			}
			return
		}

		left_num := left.(f64)
		right_num := right.(f64)

		// must be numbers
		#partial switch e.operator.type {
		case .MINUS:
			result = left_num - right_num
		case .STAR:
			result = left_num * right_num
		case .SLASH:
			result = left_num / right_num
		case .GREATER:
			result = left_num > right_num
		case .GREATER_EQUAL:
			result = left_num >= right_num
		case .LESS:
			result = left_num < right_num
		case .LESS_EQUAL:
			result = left_num <= right_num
		case:
			panic("unreachable")
		}

	case ^Ternary:
		cond := evaluate_expr(env, e.condition) or_return
		if is_truthy(cond) {
			result = evaluate_expr(env, e.left) or_return
		} else {
			result = evaluate_expr(env, e.right) or_return
		}

	case ^Grouping:
		result = evaluate_expr(env, e.content) or_return
	}

	return
}

is_truthy :: proc(v: Value) -> bool {
	if v == nil {
		return false
	}

	if b, ok := v.(bool); ok {
		return b
	}

	return true
}

is_number :: proc(v: Value) -> bool {
	_, ok := v.(f64)
	return ok
}
is_string :: proc(v: Value) -> bool {
	_, ok := v.(string)
	return ok
}

build_err :: proc(token: scanner.Token, msg: string) -> string {
	return fmt.aprintf("%s\n[line %d]", msg, token.line)
}
