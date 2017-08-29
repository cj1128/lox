package main

import (
	"bytes"
	"fmt"
)

type Expr interface {
	print() string
}

type ExprLietral struct {
	value interface{}
}

func (expr *ExprLietral) print() string {
	return fmt.Sprintf("%#v", expr.value)
}

type ExprUnary struct {
	operator *Token
	operand  Expr
}

func (expr *ExprUnary) print() string {
	return parenthesize(expr.operator.lexeme, expr.operand)
}

type ExprBinary struct {
	left     Expr
	operator *Token
	right    Expr
}

func (expr *ExprBinary) print() string {
	return parenthesize(expr.operator.lexeme, expr.left, expr.right)
}

type ExprGrouping struct {
	operand Expr
}

func (expr *ExprGrouping) print() string {
	return parenthesize("group", expr.operand)
}

/*----------  Helper Methods  ----------*/
func parenthesize(name string, exprs ...Expr) string {
	buf := &bytes.Buffer{}
	buf.WriteString("(")
	buf.WriteString(name)

	for _, expr := range exprs {
		buf.WriteString(" ")
		buf.WriteString(expr.print())
	}
	buf.WriteString(")")

	return buf.String()
}
