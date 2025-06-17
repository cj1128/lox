package loxtw

import "../parser"
import "../scanner"
import "core:fmt"
import "core:strings"


Token :: scanner.Token
Value :: union {
	f64,
	string,
	bool,
	Callable,
}

Callable :: struct {
	arity:   int,
	variant: union {
		Native_Function,
		Normal_Function,
	},
}

Native_Function :: struct {
	call: proc(env: ^Env, args: []Value) -> (Value, Evaluate_Error),
}
Normal_Function :: struct {
	stmt: ^Function_Decl_Stmt,
	call: proc(s: Normal_Function, env: ^Env, args: []Value) -> (Value, Evaluate_Error),
}

Stmt :: parser.Stmt
Expr_Stmt :: parser.Expr_Stmt
Print_Stmt :: parser.Print_Stmt
Var_Decl_Stmt :: parser.Var_Decl_Stmt
Block_Stmt :: parser.Block_Stmt
If_Stmt :: parser.If_Stmt
While_Stmt :: parser.While_Stmt

Expr :: parser.Expr
Literal :: parser.Literal_Expr
Binary :: parser.Binary_Expr
Unary :: parser.Unary_Expr
Grouping :: parser.Grouping_Expr
Ternary :: parser.Ternary_Expr
Var_Expr :: parser.Var_Expr
Assignment_Expr :: parser.Assignment_Expr
Logical_Expr :: parser.Logical_Expr
Call_Expr :: parser.Call_Expr
Function_Decl_Stmt :: parser.Function_Decl_Stmt

Evaluate_Error :: union {
	Must_Be_Two_Numbers_Or_Two_Strings,
	Must_Be_A_Number,
	Must_Be_Numbers,
	Undefined_Var,
	Not_Callable,
	Unmatched_Arity,
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
Not_Callable :: struct {
}
Unmatched_Arity :: struct {
}

execute :: proc(env: ^Env, stmt: ^Stmt, allocator := context.allocator) -> Evaluate_Error {
	switch s in stmt.variant {
	case ^While_Stmt:
		for is_truthy(evaluate(env, s.condition) or_return) {
			execute(env, s.body, allocator) or_return
		}
		return nil
	case ^If_Stmt:
		cond := evaluate(env, s.condition, allocator) or_return
		if is_truthy(cond) {
			execute(env, s.then_branch, allocator) or_return
		} else if s.else_branch != nil {
			execute(env, s.then_branch, allocator) or_return
		}

	case ^Block_Stmt:
		sub_env := new_env(env)
		for stmt in s.stmts {
			execute(sub_env, stmt, allocator) or_return
		}

	case ^Print_Stmt:
		value := evaluate(env, s.expr, allocator) or_return
		print_expr(value)

	case ^Expr_Stmt:
		evaluate(env, s.expr, allocator) or_return

	case ^Var_Decl_Stmt:
		value: Value
		if s.initializer != nil {
			value = evaluate(env, s.initializer, allocator) or_return
		}
		env_define(env, s.name.lexeme, value)

	case ^Function_Decl_Stmt:
		value: Value
		env_define(env, s.name.lexeme, new_normal_function(s))
	}

	return nil
}

evaluate :: proc(
	env: ^Env,
	expr: ^Expr,
	allocator := context.allocator,
) -> (
	result: Value,
	err: Evaluate_Error,
) {
	switch e in expr.variant {

	case ^Call_Expr:
		callee := evaluate(env, e.callee) or_return
		arguments := make([dynamic]Value)

		for arg in e.arguments {
			append(&arguments, evaluate(env, arg) or_return)
		}

		callable, ok := callee.(Callable)
		if !ok {
			return nil, Not_Callable{}
		}

		if callable.arity != len(arguments) {
			return nil, Unmatched_Arity{}
		}

		return call_callable(callable, env, arguments[:])

	case ^Logical_Expr:
		left := evaluate(env, e.left) or_return

		if e.operator.type == .OR {
			if is_truthy(left) {
				return left, nil
			}
		} else {
			if !is_truthy(left) {
				return left, nil
			}
		}

		return evaluate(env, e.right)

	case ^Var_Expr:
		val, ok := env_lookup(env, e.name.lexeme)
		if !ok {
			return nil, Undefined_Var{var = e.name}
		}
		return val, nil

	case ^Assignment_Expr:
		value := evaluate(env, e.value) or_return
		ok := env_assign(env, e.name.lexeme, value)

		if !ok {
			return nil, Undefined_Var{var = e.name}
		}

		return value, nil

	case ^Literal:
		result = literal_to_value(e.value)

	case ^Unary:
		v := evaluate(env, e.right) or_return

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
		left := evaluate(env, e.left) or_return
		right := evaluate(env, e.right) or_return

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
				result = fmt.aprintf("%s%s", left.(string), right.(string), allocator = allocator)
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
		cond := evaluate(env, e.condition) or_return
		if is_truthy(cond) {
			result = evaluate(env, e.left) or_return
		} else {
			result = evaluate(env, e.right) or_return
		}

	case ^Grouping:
		result = evaluate(env, e.content) or_return
	}

	return
}

call_callable :: proc(callable: Callable, env: ^Env, args: []Value) -> (Value, Evaluate_Error) {
	switch s in callable.variant {
	case Native_Function:
		return s.call(env, args)

	case Normal_Function:
		return s.call(s, env, args)
	}

	panic("unreachable")
}

new_normal_function :: proc(stmt: ^Function_Decl_Stmt) -> Callable {
	return Callable {
		arity = len(stmt.params),
		variant = Normal_Function{stmt = stmt, call = normal_function_call},
	}
}

normal_function_call :: proc(
	s: Normal_Function,
	env: ^Env,
	args: []Value,
) -> (
	value: Value,
	err: Evaluate_Error,
) {
	sub_env := new_env(env)

	for arg, idx in args {
		env_define(sub_env, s.stmt.params[idx].lexeme, arg)
	}

	for stmt in s.stmt.body {
		execute(sub_env, stmt) or_return
	}

	return nil, nil
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

literal_to_value :: proc(literal: scanner.Literal) -> Value {
	switch l in literal {
	case bool:
		return l
	case string:
		return l
	case f64:
		return l
	}
	return nil
}

print_expr :: proc(v: Value) {
	switch e in v {
	case f64:
		fmt.printf("%f\n", e)
	case bool:
		fmt.println(e)
	case string:
		fmt.println(e)
	case Callable:
		switch c in e.variant {
		case Native_Function:
			fmt.println("<native-fun>")
		case Normal_Function:
			fmt.println("<fun>")
		}
	}
}
