package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestExprPrint(t *testing.T) {
	expr := &ExprBinary{
		&ExprUnary{
			NewToken(MINUS, "-", nil, 1),
			&ExprLiteral{123},
		},
		NewToken(STAR, "*", nil, 1),
		&ExprGrouping{
			&ExprLiteral{45.67},
		},
	}

	expected := "(* (- 123) (group 45.67))"
	assert.Equal(t, expected, expr.print())
}
