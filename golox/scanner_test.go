/*
* @Author: CJ Ting
* @Date: 2017-02-23 14:56:58
* @Email: fatelovely1128@gmail.com
 */

package main

import (
	"github.com/stretchr/testify/assert"

	"testing"
)

func TestScannerOverall(t *testing.T) {
	assert := assert.New(t)
	src := `( ) { } , . - + ; / *
  ! != = == > >= < <=
  identifier "string" 1.234
  and class else func for if nil or print return super this true false var while
`
	scanner := NewScanner(src)
	tokens, err := scanner.ScanTokens()

	assert.Nil(err)

	expected := []*Token{
		{LEFT_PAREN, "(", nil, 1},
		{RIGHT_PAREN, ")", nil, 1},
		{LEFT_BRACE, "{", nil, 1},
		{RIGHT_BRACE, "}", nil, 1},
		{COMMA, ",", nil, 1},
		{DOT, ".", nil, 1},
		{MINUS, "-", nil, 1},
		{PLUS, "+", nil, 1},
		{SEMICOLON, ";", nil, 1},
		{SLASH, "/", nil, 1},
		{STAR, "*", nil, 1},
		{BANG, "!", nil, 2},
		{BANG_EQUAL, "!=", nil, 2},
		{EQUAL, "=", nil, 2},
		{EQUAL_EQUAL, "==", nil, 2},
		{GREATER, ">", nil, 2},
		{GREATER_EQUAL, ">=", nil, 2},
		{LESS, "<", nil, 2},
		{LESS_EQUAL, "<=", nil, 2},
		{IDENTIFIER, "identifier", nil, 3},
		{STRING, `"string"`, "string", 3},
		{NUMBER, "1.234", 1.234, 3},
		{AND, "and", nil, 4},
		{CLASS, "class", nil, 4},
		{ELSE, "else", nil, 4},
		{FUNC, "func", nil, 4},
		{FOR, "for", nil, 4},
		{IF, "if", nil, 4},
		{NIL, "nil", nil, 4},
		{OR, "or", nil, 4},
		{PRINT, "print", nil, 4},
		{RETURN, "return", nil, 4},
		{SUPER, "super", nil, 4},
		{THIS, "this", nil, 4},
		{TRUE, "true", nil, 4},
		{FALSE, "false", nil, 4},
		{VAR, "var", nil, 4},
		{WHILE, "while", nil, 4},
		{EOF, "", nil, 5},
	}

	for i := range tokens {
		assert.Equal(expected[i], tokens[i])
	}
}

func TestScannerError(t *testing.T) {
	t.Run("unterminated string", func(t *testing.T) {
		scanner := NewScanner(`"unterminated string`)
		_, err := scanner.ScanTokens()
		assert.NotNil(t, err)
	})
}

func TestScannerComment(t *testing.T) {
	t.Run("line comment", func(t *testing.T) {
		scanner := NewScanner(`
      // this should be ignored
      +
    `)
		tokens, err := scanner.ScanTokens()
		assert.Nil(t, err)
		assert.Equal(t, 2, len(tokens))
	})

	t.Run("block comment", func(t *testing.T) {
		scanner := NewScanner(`
      /*
        /*
           hello world
        */
      */
      +
    `)
		tokens, err := scanner.ScanTokens()
		assert.Nil(t, err)
		assert.Equal(t, 2, len(tokens))
	})
}
