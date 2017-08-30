package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestParserParse(t *testing.T) {
	// 1 + 2 * 3 - 4
	scanner := NewScanner("1 + 2 * 3 - 4")
	tokens, _ := scanner.ScanTokens()
	parser := NewParser(tokens)
	expr, err := parser.Parse()
	expected := NewExprBinary(
		NewExprBinary(
			NewExprLiteral(1.0),
			NewToken(PLUS, "+", nil, 1.0),
			NewExprBinary(
				NewExprLiteral(2.0),
				NewToken(STAR, "*", nil, 1.0),
				NewExprLiteral(3.0),
			),
		),
		NewToken(MINUS, "-", nil, 1.0),
		NewExprLiteral(4.0),
	)

	assert.Nil(t, err)
	assert.Equal(t, expected, expr)
}
