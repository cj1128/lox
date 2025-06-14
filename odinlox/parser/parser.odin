package parser

import "../scanner"
import "core:fmt"
import "core:mem"

Token :: scanner.Token
Token_Type :: scanner.Token_Type

// inclusive
Max_Argument_Count :: 255

@(private)
Parser :: struct {
	tokens:  []Token,
	current: int,
	result:  ^ParseResult,
}

ParseWarning :: union {
	Too_Many_Arguments,
}
Too_Many_Arguments :: struct {
}

ParseError :: union {
	Missing_Lefthand_Operand,
	Expect_Expression,
	Expect_Token,
	InvalidAssignmentTarget,
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
InvalidAssignmentTarget :: struct {
	token: Token,
}

ParseResult :: struct {
	statements: [dynamic]^Stmt,
	expr:       ^Expr,
	errors:     [dynamic]ParseError,
	warnings:   [dynamic]ParseWarning,
	arena:      mem.Dynamic_Arena,
}

parse :: proc(tokens: []Token, is_expr := false, allocator := context.allocator) -> ^ParseResult {
	result := new(ParseResult)
	mem.dynamic_arena_init(&result.arena)
	arena_alloc := mem.dynamic_arena_allocator(&result.arena)

	context.allocator = arena_alloc

	result.errors = make([dynamic]ParseError)
	result.statements = make([dynamic]^Stmt)

	p := &Parser{tokens = tokens, result = result}

	if is_expr {
		expr, err := expression(p)
		if err != nil {
			append(&p.result.errors, err)
		} else {
			p.result.expr = expr
		}
	} else {
		program(p)
	}


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
	if match(p, .VAR) {
		return var_decl(p)
	}

	return statement(p)
}

var_decl :: proc(p: ^Parser) -> (stmt: ^Stmt, err: ParseError) {
	consume(p, .IDENTIFIER, "Expect variable name")
	name := previous(p)

	initializer: ^Expr

	if match(p, .EQUAL) {
		initializer = expression(p) or_return
	}

	consume(p, .SEMICOLON, "Expect ';' after variable declaration") or_return
	return new_var_decl_stmt(name, initializer), nil
}

statement :: proc(p: ^Parser) -> (stmt: ^Stmt, err: ParseError) {
	switch {
	case match(p, .PRINT):
		return print_stmt(p)

	case match(p, .LEFT_BRACE):
		stmts := block_stmt(p) or_return
		return new_block_stmt(stmts), nil

	case match(p, .IF):
		return if_stmt(p)

	case match(p, .IF):
		return if_stmt(p)

	case match(p, .WHILE):
		return while_stmt(p)

	case match(p, .FOR):
		return for_stmt(p)

	case:
		return expression_stmt(p)
	}
}

for_stmt :: proc(p: ^Parser) -> (stmt: ^Stmt, err: ParseError) {
	consume(p, .LEFT_PAREN, "Expect '(' after 'for'") or_return

	initializer: ^Stmt
	if match(p, .SEMICOLON) {
		// initializer is nil
	} else if match(p, .VAR) {
		initializer = var_decl(p) or_return
	} else {
		initializer = expression_stmt(p) or_return
	}

	condition: ^Expr
	if !check(p, .SEMICOLON) {
		condition = expression(p) or_return
	}
	consume(p, .SEMICOLON, "Expect ';' after for loop condition") or_return

	increment: ^Expr
	if !check(p, .RIGHT_PAREN) {
		condition = expression(p) or_return
	}
	consume(p, .RIGHT_PAREN, "Expect ')' after for clauses") or_return

	body := statement(p) or_return

	if increment != nil {
		stmts := make([]^Stmt, 2)
		stmts[0] = body
		stmts[1] = new_expr_stmt(increment)
		body = new_block_stmt(stmts)
	}

	if condition == nil {
		condition = new_literal_expr(true)
	}
	body = new_while_stmt(condition, body)

	if initializer != nil {
		stmts := make([]^Stmt, 2)
		stmts[0] = initializer
		stmts[1] = body
		body = new_block_stmt(stmts)
	}

	return body, nil
}

while_stmt :: proc(p: ^Parser) -> (stmt: ^Stmt, err: ParseError) {
	consume(p, .LEFT_PAREN, "Expect '(' after 'while'") or_return
	condition := expression(p) or_return
	consume(p, .RIGHT_PAREN, "Expect ')' after while condition") or_return
	body := statement(p) or_return
	return new_while_stmt(condition, body), nil
}

if_stmt :: proc(p: ^Parser) -> (stmt: ^Stmt, err: ParseError) {
	consume(p, .LEFT_PAREN, "Expect '(' after 'if'") or_return
	condition := expression(p) or_return
	consume(p, .RIGHT_PAREN, "Expect ')' after if condition") or_return

	then_branch := statement(p) or_return
	else_branch: ^Stmt

	if match(p, .ELSE) {
		else_branch = statement(p) or_return
	}

	return new_if_stmt(condition, then_branch, else_branch), nil
}

block_stmt :: proc(p: ^Parser) -> (stmts: []^Stmt, err: ParseError) {
	result := make([dynamic]^Stmt)

	for has_content(p) && !check(p, .RIGHT_BRACE) {
		append(&result, declaration(p) or_return)
	}

	consume(p, .RIGHT_BRACE, "Expect '}' after block") or_return

	return result[:], nil
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
	return comma(p)
}

comma :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = assignment(p) or_return

	for match(p, .COMMA) {
		operator := previous(p)
		right := assignment(p) or_return
		expr = new_binary_expr(expr, operator, right)
	}

	return expr, nil
}

assignment :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	left := ternary(p) or_return

	if match(p, .EQUAL) {
		equals := previous(p)
		value := assignment(p) or_return

		target, ok := left.variant.(^Var_Expr)
		if !ok {
			return nil, InvalidAssignmentTarget{token = equals}
		}

		return new_assignment_expr(target.name, value), nil
	}

	return left, nil
}

ternary :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = logical_or(p) or_return

	if match(p, .QUESTION) {
		left := assignment(p) or_return
		consume(p, .COLON, "Expect : after ? operator") or_return
		right := assignment(p) or_return
		expr = new_ternary_expr(expr, left, right)
	}

	return expr, nil
}

logical_or :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = logical_and(p) or_return

	if match(p, .OR) {
		operator := previous(p)
		right := logical_and(p) or_return
		expr = new_logical_expr(expr, operator, right)
	}

	return expr, nil
}

logical_and :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = equality(p) or_return

	if match(p, .AND) {
		operator := previous(p)
		right := equality(p) or_return
		expr = new_logical_expr(expr, operator, right)
	}

	return expr, nil
}

equality :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = comparision(p) or_return

	for match_any(p, {.BANG_EQUAL, .EQUAL_EQUAL}) {
		operator := previous(p)
		right := comparision(p) or_return
		expr = new_binary_expr(expr, operator, right)
	}

	return expr, nil
}

comparision :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = term(p) or_return

	for match_any(p, {.GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL}) {
		operator := previous(p)
		right := term(p) or_return
		expr = new_binary_expr(expr, operator, right)
	}

	return expr, nil
}

// "+" "-"
term :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = factor(p) or_return

	for match_any(p, {.MINUS, .PLUS}) {
		operator := previous(p)
		right := factor(p) or_return
		expr = new_binary_expr(expr, operator, right)
	}

	return expr, nil
}

// "*" "/"
factor :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = unary(p) or_return

	for match_any(p, {.SLASH, .STAR}) {
		operator := previous(p)
		right := unary(p) or_return
		expr = new_binary_expr(expr, operator, right)
	}

	return expr, nil
}

unary :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	if match_any(p, {.BANG, .MINUS}) {
		operator := previous(p)
		right := unary(p) or_return
		return new_unary_expr(operator, right), nil
	}

	return call(p)
}

call :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	expr = primary(p) or_return

	for {
		if match(p, .LEFT_PAREN) {
			expr = finish_call(p, expr) or_return
		} else {
			break
		}
	}

	return expr, nil
}
finish_call :: proc(p: ^Parser, callee: ^Expr) -> (expr: ^Expr, err: ParseError) {
	arguments := make([dynamic]^Expr)

	if !check(p, .RIGHT_PAREN) {
		should_ignore := false
		for {
			if len(arguments) >= Max_Argument_Count {
				append(&p.result.warnings, Too_Many_Arguments{})
				should_ignore = true
			}

			arg := assignment(p) or_return
			if !should_ignore {
				append(&arguments, arg)
			}

			if !match(p, .COMMA) {
				break
			}
		}
	}

	consume(p, .RIGHT_PAREN, "Expect ')' after arguments") or_return
	paren := previous(p)
	return new_call_expr(paren, callee, arguments[:]), nil
}

primary :: proc(p: ^Parser) -> (expr: ^Expr, err: ParseError) {
	switch {
	case match(p, .FALSE):
		return new_literal_expr(false), nil

	case match(p, .TRUE):
		return new_literal_expr(true), nil

	case match(p, .NIL):
		return new_literal_expr(nil), nil

	case match_any(p, {.NUMBER, .STRING}):
		return new_literal_expr(previous(p).literal), nil

	case match(p, .LEFT_PAREN):
		expr = expression(p) or_return
		consume(p, .RIGHT_PAREN, "Expect ) after expression") or_return
		return new_grouping_expr(expr), nil

	case match(p, .IDENTIFIER):
		return new_var_expr(previous(p)), nil
	}

	err = Expect_Expression{}

	// Error productions
	label_missing_lefthand_operand: {
		token: Token
		switch {
		case match_any(p, {.BANG_EQUAL, .EQUAL_EQUAL}):
			token = previous(p)
			equality(p)
		case match_any(p, {.GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL}):
			token = previous(p)
			comparision(p)
		case match(p, .PLUS):
			token = previous(p)
			comparision(p)
		case match_any(p, {.SLASH, .STAR}):
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

match :: proc(p: ^Parser, type: Token_Type) -> bool {
	return match_any(p, {type})
}
match_any :: proc(p: ^Parser, types: []Token_Type) -> bool {
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
