package main

import (
	"testing"

	"cjting.me/lox/scanner"
	"github.com/stretchr/testify/assert"
)

func TestParserParse(t *testing.T) {
	// 1 + 2 * 3 - 4
	tokens, _ := scanner.Scan("1 + 2 * 3 - 4")
	parser := NewParser()
	expr, err := parser.Parse(tokens)

	expected := NewExprBinary(
		NewExprBinary(
			NewExprLiteral(1.0),
			scanner.NewToken(scanner.PLUS, "+", nil, 1.0),
			NewExprBinary(
				NewExprLiteral(2.0),
				scanner.NewToken(scanner.STAR, "*", nil, 1.0),
				NewExprLiteral(3.0),
			),
		),
		scanner.NewToken(scanner.MINUS, "-", nil, 1.0),
		NewExprLiteral(4.0),
	)

	assert.Nil(t, err)
	assert.Equal(t, expected, expr)
}
