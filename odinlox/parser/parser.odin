package parser

import "../scanner"
import "core:fmt"
import vmem "core:mem/virtual"

Token :: scanner.Token
Token_Type :: scanner.Token_Type

@(private)
Parser :: struct {
	tokens:  []Token,
	current: int,
	result:  ^ParseResult,
}

Error :: struct {
}

ParseResult :: struct {
	ast:    ^Expr,
	errors: [dynamic]Error,
	arena:  ^vmem.Arena,
}

parse :: proc(tokens: []Token, allocator := context.allocator) -> ^ParseResult {
	arena: vmem.Arena
	arena_err := vmem.arena_init_growing(&arena)
	ensure(arena_err == nil)
	arena_alloc := vmem.arena_allocator(&arena)

	context.allocator = arena_alloc

	result := new(ParseResult)
	result.arena = &arena
	result.errors = make([dynamic]Error)

	p := &Parser{tokens = tokens, result = result}

	result.ast = expression(p)

	return result
}
destroy :: proc(result: ^ParseResult) {
	vmem.arena_destroy(result.arena)
}

expression :: proc(p: ^Parser) -> ^Expr {
	return equality(p)
}

equality :: proc(p: ^Parser) -> ^Expr {
	expr := comparision(p)

	for match(p, {Token_Type.BANG_EQUAL, Token_Type.EQUAL_EQUAL}) {
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

term :: proc(p: ^Parser) -> ^Expr {
	expr := factor(p)

	for match(p, {.MINUS, .PLUS}) {
		operator := previous(p)
		right := factor(p)
		expr = binary_expr(expr, operator, right)
	}

	return expr
}

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
		// TODO: assert there is a rigth paren
		return grouping_expr(expr)
	}

	// TODO: should throw
	panic("TODO")
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
	// fmt.println("peek", p.current, len(p.tokens))
	return p.tokens[p.current]
}
previous :: proc(p: ^Parser) -> Token {
	return p.tokens[p.current - 1]
}
has_content :: proc(p: ^Parser) -> bool {
	return p.current < len(p.tokens)
}
