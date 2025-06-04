package lox

import "./parser"
import "./scanner"
import "core:fmt"
import "core:strings"

Expr :: parser.Expr
Literal :: parser.Literal
Binary :: parser.Binary
Unary :: parser.Unary
Grouping :: parser.Grouping

Value :: scanner.Literal

Must_Be_A_Number :: "Operand must be a number"
Must_Be_Numbers :: "Operands must be numbers"

evaluate :: proc(expr: ^Expr) -> (result: Value, err: Maybe(string)) {
	switch e in expr.variant {

	case ^Literal:
		result = e.value

	case ^Unary:
		v: Value
		v, err = evaluate(e.right)
		if err != nil {
			return
		}

		#partial switch e.operator.type {
		case .BANG:
			result = !is_truthy(v)

		case .MINUS:
			if !is_number(v) {
				err = build_err(e.operator, Must_Be_A_Number)
				return
			}

			result = -v.(f64)
		case:
			panic("unreachable")
		}

	case ^Binary:
		left, right: Value
		left, err = evaluate(e.left)
		if err != nil {
			return
		}
		right, err = evaluate(e.right)
		if err != nil {
			return
		}

		#partial switch e.operator.type {
		case .EQUAL_EQUAL:
			result = left == right
			return

		case .BANG_EQUAL:
			result = left != right
			return

		case .PLUS:
			if is_number(left) && is_number(right) {
				result = left.(f64) + right.(f64)
			} else if is_string(left) && is_string(right) {
				result = fmt.tprintf("%s%s", left.(string), right.(string))
			} else {
				err = build_err(e.operator, "Operands must be two numbers or two strings")
			}
			return
		}

		if !is_number(left) || !is_number(right) {
			err = build_err(e.operator, Must_Be_Numbers)
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

	case ^Grouping:
		result, err = evaluate(e.content)
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
