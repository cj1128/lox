package main

import "fmt"

type Parser struct {
	tokens  []*Token
	current int
	length  int
}

func NewParser(tokens []*Token) *Parser {
	return &Parser{
		tokens:  tokens,
		current: 0,
		length:  len(tokens),
	}
}

func (p *Parser) Expression() Expr {
	return p.Equality()
}

func (p *Parser) Parse() (expr Expr, err error) {
	defer func() {
		if e := recover(); e != nil {
			err = fmt.Errorf("parse error: %v", e)
		}
	}()

	expr = p.Expression()
	return
}

func (p *Parser) Equality() Expr {
	expr := p.Comparison()

	for p.match(BANG_EQUAL, EQUAL_EQUAL) {
		operator := p.previous()
		right := p.Comparison()
		expr = NewExprBinary(expr, operator, right)
	}

	return expr
}

func (p *Parser) Comparison() Expr {
	expr := p.Addition()

	for p.match(GREATER, GREATER_EQUAL, LESS, LESS_EQUAL) {
		operator := p.previous()
		right := p.Addition()
		expr = NewExprBinary(expr, operator, right)
	}

	return expr
}

func (p *Parser) Addition() Expr {
	expr := p.Multiplication()

	for p.match(PLUS, MINUS) {
		operator := p.previous()
		right := p.Multiplication()
		expr = NewExprBinary(expr, operator, right)
	}

	return expr
}

func (p *Parser) Multiplication() Expr {
	expr := p.Unary()
	for p.match(STAR, SLASH) {
		operator := p.previous()
		right := p.Unary()
		expr = NewExprBinary(expr, operator, right)
	}

	return expr
}

func (p *Parser) Unary() Expr {
	if p.match(BANG, MINUS) {
		operator := p.previous()
		operand := p.Unary()
		return NewExprUnary(operator, operand)
	}

	return p.Primary()
}

func (p *Parser) Primary() Expr {
	if p.match(TRUE) {
		return NewExprLiteral(true)
	}

	if p.match(FALSE) {
		return NewExprLiteral(false)
	}

	if p.match(NIL) {
		return NewExprLiteral(nil)
	}

	if p.match(NUMBER, STRING) {
		return NewExprLiteral(p.previous().literal)
	}

	if p.match(LEFT_PAREN) {
		expr := p.Expression()
		p.consume(RIGHT_PAREN, "expect ')' after expression")
		return NewExprGrouping(expr)
	}

	panic(fmt.Sprintf("expect expression, got: %v", p.peek()))
}

/*----------  Helper Mehtods  ----------*/
func (p *Parser) isAtEnd() bool {
	return p.peek().typ == EOF
}

func (p *Parser) peek() *Token {
	return p.tokens[p.current]
}

func (p *Parser) previous() *Token {
	return p.tokens[p.current-1]
}

func (p *Parser) check(typ TokenType) bool {
	if p.isAtEnd() {
		return false
	}
	return p.peek().typ == typ
}

func (p *Parser) advance() *Token {
	if !p.isAtEnd() {
		p.current++
	}
	return p.previous()
}

func (p *Parser) match(tokenTypes ...TokenType) bool {
	for _, typ := range tokenTypes {
		if p.check(typ) {
			p.advance()
			return true
		}
	}
	return false
}

func (p *Parser) consume(typ TokenType, msg string) {
	if p.check(typ) {
		p.advance()
		return
	}
	panic(msg)
}
