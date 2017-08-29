package main

import "fmt"

type TokenType string

const (
	// Single-character tokens
	LEFT_PAREN  TokenType = "Left_Paren"  // (
	RIGHT_PAREN           = "Right_Paren" // )
	LEFT_BRACE            = "Left_Brace"  // {
	RIGHT_BRACE           = "Right_Brace" // }
	COMMA                 = "Comma"       // ,
	DOT                   = "Dot"         // .
	MINUS                 = "Minus"       // -
	PLUS                  = "Plus"        // +
	SEMICOLON             = "Semicolon"   // ;
	SLASH                 = "Slash"       // /
	STAR                  = "Star"        // *

	// One or two character tokens
	BANG          = "Bang"          // !
	BANG_EQUAL    = "Bang_Equal"    // !=
	EQUAL         = "Equal"         // =
	EQUAL_EQUAL   = "Equal_Equal"   // ==
	GREATER       = "Greater"       // >
	GREATER_EQUAL = "Greater_Equal" // >=
	LESS          = "Less"          // <
	LESS_EQUAL    = "Less_Equal"    // <=

	// Literals
	IDENTIFIER = "Identifier"
	STRING     = "String"
	NUMBER     = "Number"

	// Keywords
	AND    = "And"
	CLASS  = "Class"
	ELSE   = "Else"
	FUNC   = "Func"
	FOR    = "For"
	IF     = "If"
	NIL    = "Nil"
	OR     = "Or"
	PRINT  = "Print"
	RETURN = "Return"
	SUPER  = "Super"
	THIS   = "This"
	TRUE   = "True"
	FALSE  = "False"
	VAR    = "Var"
	WHILE  = "While"

	EOF = "EOF"
)

type Token struct {
	typ     TokenType
	lexeme  string
	literal interface{} // string or number
	line    int
}

func (t *Token) String() string {
	return fmt.Sprintf("[%d] %s: %s (%#v)", t.line, t.typ, t.lexeme, t.literal)
}

var KeywordToken = map[string]TokenType{
	"and":    AND,
	"class":  CLASS,
	"else":   ELSE,
	"false":  FALSE,
	"for":    FOR,
	"func":   FUNC,
	"if":     IF,
	"nil":    NIL,
	"or":     OR,
	"print":  PRINT,
	"return": RETURN,
	"super":  SUPER,
	"this":   THIS,
	"true":   TRUE,
	"var":    VAR,
	"while":  WHILE,
}

func NewToken(
	typ TokenType,
	lexeme string,
	literal interface{},
	line int,
) *Token {
	return &Token{
		typ:     typ,
		lexeme:  lexeme,
		literal: literal,
		line:    line,
	}
}
