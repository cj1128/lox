package parser

import "../scanner"
import "core:fmt"
import "core:mem"

Token :: scanner.Token
Token_Type :: scanner.Token_Type

@(private)
Parser :: struct {
	tokens:  []Token,
	current: int,
	result:  ^ParseResult,
}

Error :: struct {
	msg: string,
}

ParseResult :: struct {
	ast:    ^Expr,
	errors: [dynamic]Error,
	arena:  mem.Dynamic_Arena,
}

parse :: proc(tokens: []Token, allocator := context.allocator) -> ^ParseResult {
	result := new(ParseResult)
	mem.dynamic_arena_init(&result.arena)
	arena_alloc := mem.dynamic_arena_allocator(&result.arena)

	context.allocator = arena_alloc

	result.errors = make([dynamic]Error)

	p := &Parser{tokens = tokens, result = result}

	result.ast = expression(p)

	return result
}
destroy :: proc(result: ^ParseResult) {
	mem.dynamic_arena_destroy(&result.arena)
	free(result)
}

expression :: proc(p: ^Parser) -> ^Expr {
	return ternary(p)
}

ternary :: proc(p: ^Parser) -> ^Expr {
	expr := comma(p)

	if match(p, {.QUESTION}) {
		left := expression(p)
		if consume(p, .COLON, "Expect : after ? operator") {
			right := expression(p)
			expr = ternary_expr(expr, left, right)
		} else {
			return nil
		}
	}

	return expr
}

comma :: proc(p: ^Parser) -> ^Expr {
	expr := equality(p)

	for match(p, {.COMMA}) {
		operator := previous(p)
		right := equality(p)
		expr = binary_expr(expr, operator, right)
	}

	return expr
}


equality :: proc(p: ^Parser) -> ^Expr {
	expr := comparision(p)

	for match(p, {.BANG_EQUAL, .EQUAL_EQUAL}) {
		operator := previous(p)
		right := comparision(p)
		expr = binary_expr(expr, operator, right)
	}

	return expr
}

comparision :: proc(p: ^Parser) -> ^Expr {
	expr := term(p)

	for match(p, {.GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL}) {
		operator := previous(p)
		right := term(p)
		expr = binary_expr(expr, operator, right)
	}

	return expr
}

// "+" "-"
term :: proc(p: ^Parser) -> ^Expr {
	expr := factor(p)

	for match(p, {.MINUS, .PLUS}) {
		operator := previous(p)
		right := factor(p)
		expr = binary_expr(expr, operator, right)
	}

	return expr
}

// "*" "/"
factor :: proc(p: ^Parser) -> ^Expr {
	expr := unary(p)

	for match(p, {.SLASH, .STAR}) {
		operator := previous(p)
		right := unary(p)
		expr = binary_expr(expr, operator, right)
	}

	return expr
}

unary :: proc(p: ^Parser) -> ^Expr {
	if match(p, {.BANG, .MINUS}) {
		operator := previous(p)
		right := unary(p)
		return unary_expr(operator, right)
	}

	return primary(p)
}

primary :: proc(p: ^Parser) -> ^Expr {
	switch {
	case match(p, {.FALSE}):
		return literal_expr(false)

	case match(p, {.TRUE}):
		return literal_expr(true)

	case match(p, {.NIL}):
		return literal_expr(nil)

	case match(p, {.NUMBER, .STRING}):
		return literal_expr(previous(p).literal)

	case match(p, {.LEFT_PAREN}):
		expr := expression(p)
		if consume(p, .RIGHT_PAREN, "Expect ) after expression") {
			return grouping_expr(expr)
		} else {
			return nil
		}

	// Error productions
	case match(p, {.BANG_EQUAL, .EQUAL_EQUAL}):
		add_error(p, "Missing left-hand operand")
		equality(p)
		return nil
	case match(p, {.GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL}):
		add_error(p, "Missing left-hand operand")
		comparision(p)
		return nil
	case match(p, {.PLUS}):
		add_error(p, "Missing left-hand operand")
		term(p)
		return nil
	case match(p, {.SLASH, .STAR}):
		add_error(p, "Missing left-hand operand")
		factor(p)
		return nil
	}

	add_error(p, "Expect expression")

	return nil
}

add_error :: proc(p: ^Parser, msg: string) {
	append(&p.result.errors, Error{msg = msg})
}

consume :: proc(p: ^Parser, type: Token_Type, msg: string) -> bool {
	if !has_content(p) || p.tokens[p.current].type != type {
		add_error(p, msg)
		return false
	}

	advance(p)

	return true
}

//
//
//

match :: proc(p: ^Parser, types: []Token_Type) -> bool {
	for type in types {
		if check(p, type) {
			advance(p)
			return true
		}
	}

	return false
}
check :: proc(p: ^Parser, type: Token_Type) -> bool {
	if !has_content(p) {
		return false
	}
	return peek(p).type == type
}
advance :: proc(p: ^Parser) -> Token {
	result := p.tokens[p.current]
	p.current += 1
	return result
}
peek :: proc(p: ^Parser) -> Token {
	return p.tokens[p.current]
}
previous :: proc(p: ^Parser) -> Token {
	return p.tokens[p.current - 1]
}
has_content :: proc(p: ^Parser) -> bool {
	return p.current < len(p.tokens)
}
