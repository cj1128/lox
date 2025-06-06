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

ParseError :: union {
	Missing_Lefthand_Operand,
	Expect_Expression,
	Expect_Token,
}
Missing_Lefthand_Operand :: struct {
	token_type: Token_Type,
}
Expect_Expression :: struct {
}
Expect_Token :: struct {
	token_type: Token_Type,
	msg:        string,
}

ParseResult :: struct {
	statements: [dynamic]^Stmt,
	errors:     [dynamic]ParseError,
	arena:      mem.Dynamic_Arena,
}

parse :: proc(tokens: []Token, allocator := context.allocator) -> ^ParseResult {
	result := new(ParseResult)
	mem.dynamic_arena_init(&result.arena)
	arena_alloc := mem.dynamic_arena_allocator(&result.arena)

	context.allocator = arena_alloc

	result.errors = make([dynamic]ParseError)
	result.statements = make([dynamic]^Stmt)

	p := &Parser{tokens = tokens, result = result}

	program(p)

	return result
}
destroy :: proc(result: ^ParseResult) {
	mem.dynamic_arena_destroy(&result.arena)
	free(result)
}

//
//
//

program :: proc(p: ^Parser) {
	for has_content(p) {
		if p.tokens[p.current].type == .EOF {
			break
		}
		stmt, err := declaration(p)

		// TODO: error sync
		if err != nil {
			append(&p.result.errors, err)
			break

		} else {
			append(&p.result.statements, stmt)
		}
	}
}

declaration :: proc(p: ^Parser) -> (stmt: ^Stmt, err: ParseError) {
	if match(p, {.VAR}) {
		return var_decl(p)
	}

	return statement(p)
}

var_decl :: proc(p: ^Parser) -> (stmt: ^Stmt, err: ParseError) {
	consume(p, .IDENTIFIER, "Expect variable name")
	name := previous(p)

	initializer: ^Expr

	if match(p, {.EQUAL}) {
		initializer = expression(p) or_return
	}

	consume(p, .SEMICOLON, "Expect ';' after variable declaration") or_return
	return new_var_decl_stmt(name, initializer), nil
}

statement :: proc(p: ^Parser) -> (stmt: ^Stmt, err: ParseError) {
	if match(p, {.PRINT}) {
		return print_stmt(p)
	}

	return expression_stmt(p)
}

print_stmt :: proc(p: ^Parser) -> (stmt: ^Stmt, err: ParseError) {
	expr := expression(p) or_return
	consume(p, .SEMICOLON, "Expect ';' after value") or_return
	return new_print_stmt(expr), nil
}

expression_stmt :: proc(p: ^Parser) -> (stmt: ^Stmt, err: ParseError) {
	expr := expression(p) or_return
	consume(p, .SEMICOLON, "Expect ';' after value") or_return
	return new_expr_stmt(expr), nil
}

expression :: proc(p: ^Parser) -> (^Expr, ParseError) {
	return ternary(p)
}

ternary :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = comma(p) or_return

	if match(p, {.QUESTION}) {
		left := expression(p) or_return
		consume(p, .COLON, "Expect : after ? operator") or_return
		right := expression(p) or_return
		expr = new_ternary_expr(expr, left, right)
	}

	return expr, nil
}

comma :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = equality(p) or_return

	for match(p, {.COMMA}) {
		operator := previous(p)
		right := equality(p) or_return
		expr = new_binary_expr(expr, operator, right)
	}

	return expr, nil
}

equality :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = comparision(p) or_return

	for match(p, {.BANG_EQUAL, .EQUAL_EQUAL}) {
		operator := previous(p)
		right := comparision(p) or_return
		expr = new_binary_expr(expr, operator, right)
	}

	return expr, nil
}

comparision :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = term(p) or_return

	for match(p, {.GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL}) {
		operator := previous(p)
		right := term(p) or_return
		expr = new_binary_expr(expr, operator, right)
	}

	return expr, nil
}

// "+" "-"
term :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = factor(p) or_return

	for match(p, {.MINUS, .PLUS}) {
		operator := previous(p)
		right := factor(p) or_return
		expr = new_binary_expr(expr, operator, right)
	}

	return expr, nil
}

// "*" "/"
factor :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = unary(p) or_return

	for match(p, {.SLASH, .STAR}) {
		operator := previous(p)
		right := unary(p) or_return
		expr = new_binary_expr(expr, operator, right)
	}

	return expr, nil
}

unary :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	if match(p, {.BANG, .MINUS}) {
		operator := previous(p)
		right := unary(p) or_return
		return new_unary_expr(operator, right), nil
	}

	return primary(p)
}

primary :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	switch {
	case match(p, {.FALSE}):
		return new_literal_expr(false), nil

	case match(p, {.TRUE}):
		return new_literal_expr(true), nil

	case match(p, {.NIL}):
		return new_literal_expr(nil), nil

	case match(p, {.NUMBER, .STRING}):
		return new_literal_expr(previous(p).literal), nil

	case match(p, {.LEFT_PAREN}):
		expr = expression(p) or_return
		consume(p, .RIGHT_PAREN, "Expect ) after expression") or_return
		return new_grouping_expr(expr), nil

	case match(p, {.IDENTIFIER}):
		return new_var_expr(previous(p)), nil
	}

	err = Expect_Expression{}

	// Error productions
	label_missing_lefthand_operand: {
		token: Token
		switch {
		case match(p, {.BANG_EQUAL, .EQUAL_EQUAL}):
			token = previous(p)
			equality(p)
		case match(p, {.GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL}):
			token = previous(p)
			comparision(p)
		case match(p, {.PLUS}):
			token = previous(p)
			comparision(p)
		case match(p, {.SLASH, .STAR}):
			token = previous(p)
			factor(p)
		case:
			break label_missing_lefthand_operand
		}

		return nil, Missing_Lefthand_Operand{token_type = token.type}
	}

	return nil, err
}

consume :: proc(p: ^Parser, type: Token_Type, msg: string) -> ParseError {
	if !has_content(p) || p.tokens[p.current].type != type {
		return Expect_Token{msg = msg, token_type = type}
	}

	advance(p)

	return nil
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
