package main

import (
	"fmt"
)

type Parser struct {
	tokens  []*Token
	current int
	length  int
}

type ParseError struct {
	token *Token
	msg   string
}

func NewParseError(token *Token, msg string) *ParseError {
	return &ParseError{token, msg}
}

func (pe *ParseError) Error() string {
	token := pe.token
	position := ""
	if token.typ == EOF {
		position = "at end"
	} else {
		position = fmt.Sprintf(`at '%s'`, token.lexeme)
	}
	return fmt.Sprintf("line %d, %s, %s", token.line, position, pe.msg)
}

func NewParser() *Parser {
	return &Parser{}
}

func (p *Parser) Parse(tokens []*Token) (result []Stmt, err error) {
	p.reset(tokens)
	defer func() {
		if e := recover(); e != nil {
			if pe, ok := e.(*ParseError); ok {
				err = pe
			} else {
				panic(err)
			}
		}
	}()
	for !p.isAtEnd() {
		result = append(result, p.Declaration())
	}
	return
}

/*----------  Private Methods  ----------*/

func (p *Parser) Declaration() (result Stmt) {
	// defer func() {
	// 	if err := recover(); err != nil {
	// 		if _, ok := err.(*ParseError); ok {
	// 			p.synchronize()
	// 			result = nil
	// 		}
	// 	}
	// }()

	switch true {
	case p.match(VAR):
		result = p.VarDeclaration()
	case p.match(FUNC):
		result = p.FuncDeclaration("function")
	default:
		result = p.Statement()
	}

	return
}

// kind should be one of: `function`
func (p *Parser) FuncDeclaration(kind string) Stmt {
	name := p.consume(IDENTIFIER, "expect "+kind+" name")
	p.consume(LEFT_PAREN, "expect '(' after "+kind+" name")
	var parameters []*Token
	if !p.check(RIGHT_PAREN) {
		parameters = append(parameters, p.consume(IDENTIFIER, "expect parameter name"))
		for p.match(COMMA) {
			if len(parameters) == 8 {
				panic(NewParseError(p.peek(), "can't have more than 8 arguments"))
			}
			parameters = append(parameters, p.consume(IDENTIFIER, "expect parameter name"))
		}
	}
	p.consume(RIGHT_PAREN, "expect ')' after parameters")
	p.consume(LEFT_BRACE, "expect '{' after "+kind+" body")
	body := p.BlockStatement()
	return NewStmtFuncDecl(name, parameters, body)
}

func (p *Parser) VarDeclaration() Stmt {
	name := p.consume(IDENTIFIER, "expect variable name")
	var value Expr
	if p.match(EQUAL) {
		value = p.Expression()
	}
	p.consume(SEMICOLON, "expect ';' after variable declaration")
	return NewStmtVarDecl(name, value)
}

func (p *Parser) Statement() Stmt {
	if p.match(PRINT) {
		return p.PrintStatement()
	}

	if p.match(LEFT_BRACE) {
		return NewStmtBlock(p.BlockStatement())
	}

	if p.match(IF) {
		return p.IfStatement()
	}

	if p.match(WHILE) {
		return p.WhileStatement()
	}

	if p.match(FOR) {
		return p.ForStatement()
	}

	if p.match(RETURN) {
		return p.ReturnStatement()

	}

	return p.ExpressionStatement()
}

func (p *Parser) ReturnStatement() Stmt {
	token := p.previous()
	var value Expr
	if !p.check(SEMICOLON) {
		value = p.Expression()
	}
	p.consume(SEMICOLON, "expect ';' after return value")
	return NewStmtReturn(token, value)
}

// desugar for to while statement
func (p *Parser) ForStatement() Stmt {
	p.consume(LEFT_PAREN, "expect '(' after for")
	var initializer Stmt

	if !p.check(SEMICOLON) {
		if p.match(VAR) {
			initializer = p.VarDeclaration()
		} else {
			initializer = p.ExpressionStatement()
		}
	}

	var condition Expr
	if !p.check(SEMICOLON) {
		condition = p.Expression()
	}
	p.consume(SEMICOLON, "expect ';' after loop condition")

	var increment Expr
	if !p.check(RIGHT_PAREN) {
		increment = p.Expression()
	}
	p.consume(RIGHT_PAREN, "expect ')' after clauses")

	body := p.Statement()

	if increment != nil {
		body = NewStmtBlock([]Stmt{
			body,
			NewStmtExpression(increment),
		})
	}

	if condition == nil {
		condition = NewExprLiteral(true)
	}
	body = NewStmtWhile(condition, body)

	if initializer != nil {
		body = NewStmtBlock([]Stmt{
			initializer,
			body,
		})
	}

	return body
}

func (p *Parser) WhileStatement() Stmt {
	p.consume(LEFT_PAREN, "expect '(' after while")
	condition := p.Expression()
	p.consume(RIGHT_PAREN, "expect ')' after condition")
	body := p.Statement()
	return NewStmtWhile(condition, body)
}

func (p *Parser) IfStatement() Stmt {
	p.consume(LEFT_PAREN, "expect '(' after if")
	condition := p.Expression()
	p.consume(RIGHT_PAREN, "expect ')' after if condition")
	trueBranch := p.Statement()
	var falseBranch Stmt

	if p.match(ELSE) {
		falseBranch = p.Statement()
	}
	return NewStmtIf(condition, trueBranch, falseBranch)
}

func (p *Parser) BlockStatement() []Stmt {
	var stmts []Stmt
	for !p.check(RIGHT_BRACE) && !p.isAtEnd() {
		stmts = append(stmts, p.Declaration())
	}
	p.consume(RIGHT_BRACE, "expect '}' after block")
	return stmts
}

func (p *Parser) PrintStatement() Stmt {
	expr := p.Expression()
	p.consume(SEMICOLON, "expect ';' after value")
	return NewStmtPrint(expr)
}

func (p *Parser) ExpressionStatement() Stmt {
	expr := p.Expression()
	p.consume(SEMICOLON, "expect ';' after value")
	return NewStmtExpression(expr)
}

func (p *Parser) Expression() Expr {
	return p.Assignment()
}

func (p *Parser) Assignment() Expr {
	expr := p.LogicalOr()

	if p.match(EQUAL) {
		equal := p.previous()
		value := p.Assignment()

		if e, ok := expr.(*ExprVariable); ok {
			return NewExprAssignment(e.name, value)
		}

		panic(NewParseError(equal, "invalid assignment target"))
	}

	return expr
}

func (p *Parser) LogicalOr() Expr {
	expr := p.LogicalAnd()

	for p.match(OR) {
		operator := p.previous()
		right := p.LogicalAnd()
		expr = NewExprLogical(expr, operator, right)
	}

	return expr
}

func (p *Parser) LogicalAnd() Expr {
	expr := p.Equality()

	for p.match(AND) {
		operator := p.previous()
		right := p.Equality()
		expr = NewExprLogical(expr, operator, right)
	}

	return expr
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

	return p.Call()
}

func (p *Parser) Call() Expr {
	expr := p.Primary()
	for true {
		if p.match(LEFT_PAREN) {
			expr = p.finishCall(expr)
		} else {
			break
		}
	}
	return expr
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

	if p.match(IDENTIFIER) {
		return NewExprVariable(p.previous())
	}

	panic(NewParseError(p.peek(), "expect expression"))
}

/*----------  Helper Mehtods  ----------*/
func (p *Parser) reset(tokens []*Token) {
	p.tokens = tokens
	p.length = len(tokens)
	p.current = 0
}

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

func (p *Parser) consume(typ TokenType, msg string) *Token {
	if p.check(typ) {
		return p.advance()
	}
	panic(NewParseError(p.peek(), msg))
}

func (p *Parser) finishCall(callee Expr) Expr {
	var arguments []Expr
	if !p.check(RIGHT_PAREN) {
		arguments = append(arguments, p.Expression())
		for p.match(COMMA) {
			// in order to compitable with C implementation, we limit
			// argument size
			if len(arguments) >= 8 {
				panic(NewParseError(p.peek(), "can't have more than 8 arguments"))
			}
			arguments = append(arguments, p.Expression())
		}
	}

	paren := p.consume(RIGHT_PAREN, "exepct ')' after function arguments")
	return NewExprCall(callee, paren, arguments)
}

func (p *Parser) synchronize() {
}
