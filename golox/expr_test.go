package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestExprPrint(t *testing.T) {
	expr := NewExprBinary(
		NewExprUnary(
			NewToken(MINUS, "-", nil, 1),
			NewExprLiteral(123),
		),
		NewToken(STAR, "*", nil, 1),
		NewExprGrouping(
			NewExprLiteral(45.67),
		),
	)

	expected := "(* (- 123) (group 45.67))"
	assert.Equal(t, expected, expr.print())
}
