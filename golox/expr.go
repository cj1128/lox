package main

import (
	"bytes"

	"cjting.me/lox/scanner"
)

type Expr interface {
	Print() string // for debug
	Eval(env *Env) Val
}

/*----------  Variable  ----------*/
type ExprVariable struct {
	name *scanner.Token
}

func NewExprVariable(name *scanner.Token) *ExprVariable {
	return &ExprVariable{name}
}

func (expr *ExprVariable) Print() string {
	return expr.name.Lexeme
}

/*----------  Literal  ----------*/

type ExprLiteral struct {
	value interface{}
}

func NewExprLiteral(val interface{}) *ExprLiteral {
	return &ExprLiteral{val}
}

func (expr *ExprLiteral) Print() string {
	return sprintf("%#v", expr.value)
}

/*----------  Unary  ----------*/

type ExprUnary struct {
	operator *scanner.Token
	operand  Expr
}

func NewExprUnary(operator *scanner.Token, operand Expr) *ExprUnary {
	return &ExprUnary{operator, operand}
}

func (expr *ExprUnary) Print() string {
	return parenthesize(expr.operator.Lexeme, expr.operand)
}

/*----------  Binary  ----------*/

type ExprBinary struct {
	left     Expr
	operator *scanner.Token
	right    Expr
}

func NewExprBinary(left Expr, operator *scanner.Token, right Expr) *ExprBinary {
	return &ExprBinary{left, operator, right}
}

func (expr *ExprBinary) Print() string {
	return parenthesize(expr.operator.Lexeme, expr.left, expr.right)
}

/*----------  Grouping  ----------*/

type ExprGrouping struct {
	operand Expr
}

func NewExprGrouping(operand Expr) *ExprGrouping {
	return &ExprGrouping{operand}
}

func (expr *ExprGrouping) Print() string {
	return parenthesize("group", expr.operand)
}

/*----------  Assignment  ----------*/
type ExprAssignment struct {
	name *scanner.Token
	val  Expr
}

func NewExprAssignment(name *scanner.Token, val Expr) *ExprAssignment {
	return &ExprAssignment{name, val}
}

func (expr *ExprAssignment) Print() string {
	return sprintf("(assign %s %v)", expr.name.Lexeme, expr.val)
}

/*----------  Logical  ----------*/
type ExprLogical struct {
	left     Expr
	operator *scanner.Token
	right    Expr
}

func NewExprLogical(left Expr, operator *scanner.Token, right Expr) *ExprLogical {
	return &ExprLogical{left, operator, right}
}

func (expr *ExprLogical) Print() string {
	return parenthesize(expr.operator.Lexeme, expr.left, expr.right)
}

/*----------  Function Call  ----------*/
type ExprCall struct {
	callee Expr
	// close paren
	paren     *scanner.Token
	arguments []Expr
}

func NewExprCall(callee Expr, paren *scanner.Token, arguments []Expr) Expr {
	return &ExprCall{callee, paren, arguments}
}

func (expr *ExprCall) Print() string {
	return parenthesize(expr.callee.Print(), expr.arguments...)
}

/*----------  Helper Methods  ----------*/

func parenthesize(name string, exprs ...Expr) string {
	buf := &bytes.Buffer{}
	buf.WriteString("(")
	buf.WriteString(name)

	for _, expr := range exprs {
		buf.WriteString(" ")
		buf.WriteString(expr.Print())
	}
	buf.WriteString(")")

	return buf.String()
}
