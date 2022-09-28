package main

import (
	"testing"

	"cjting.me/lox/scanner"
	"github.com/stretchr/testify/assert"
)

func TestExprPrint(t *testing.T) {
	expr := NewExprBinary(
		NewExprUnary(
			scanner.NewToken(scanner.MINUS, "-", nil, 1),
			NewExprLiteral(123),
		),
		scanner.NewToken(scanner.STAR, "*", nil, 1),
		NewExprGrouping(
			NewExprLiteral(45.67),
		),
	)

	expected := "(* (- 123) (group 45.67))"
	assert.Equal(t, expected, expr.Print())
}
