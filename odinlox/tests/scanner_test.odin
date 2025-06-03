package tests

import "../scanner"
import "core:fmt"
import "core:slice"
import "core:testing"

@(test)
basic_scanner :: proc(t: ^testing.T) {
	tokens, errors := scanner.scan(
		`( ) { } , . - + ; / *
  ! != = == > >= < <=
  identifier "string" 1.234000
  and class else fun for if nil or print return super this true false var while
`,
	)
	testing.expect(t, len(errors) == 0)

	expected := []scanner.Token {
		{type = .LEFT_PAREN},
		{type = .RIGHT_PAREN},
		{type = .LEFT_BRACE},
		{type = .RIGHT_BRACE},
		{type = .COMMA},
		{type = .DOT},
		{type = .MINUS},
		{type = .PLUS},
		{type = .SEMICOLON},
		{type = .SLASH},
		{type = .STAR},
		{type = .BANG},
		{type = .BANG_EQUAL},
		{type = .EQUAL},
		{type = .EQUAL_EQUAL},
		{type = .GREATER},
		{type = .GREATER_EQUAL},
		{type = .LESS},
		{type = .LESS_EQUAL},
		{type = .IDENTIFIER, lexeme = "identifier"},
		{type = .STRING, literal = "string"},
		{type = .NUMBER, lexeme = "1.234000", literal = 1.234},
		{type = .AND},
		{type = .CLASS},
		{type = .ELSE},
		{type = .FUN},
		{type = .FOR},
		{type = .IF},
		{type = .NIL},
		{type = .OR},
		{type = .PRINT},
		{type = .RETURN},
		{type = .SUPER},
		{type = .THIS},
		{type = .TRUE},
		{type = .FALSE},
		{type = .VAR},
		{type = .WHILE},
		{type = .EOF},
	}

	for token, i in tokens {
		testing.expect(
			t,
			token == expected[i],
			fmt.tprintf("index %d: expected %v, got %v", i, expected[i], token),
		)
	}
}

@(test)
scanner_error :: proc(t: ^testing.T) {
	tokens, errors := scanner.scan(`"unterminated string`)
	testing.expect(t, len(tokens) == 1) // EOF
	testing.expect(t, tokens[0].type == .EOF)

	testing.expect(t, len(errors) == 1)
	testing.expect(t, errors[0].type == .Unterminated_String)
}

@(test)
line_comment :: proc(t: ^testing.T) {
	tokens, errors := scanner.scan(`
    // this is a comment
    +
  `)
	testing.expect(t, len(errors) == 0)
	testing.expect(t, len(tokens) == 2)
	testing.expect(t, tokens[0].type == .PLUS)
	testing.expect(t, tokens[1].type == .EOF)
}

@(test)
block_comment_ok :: proc(t: ^testing.T) {
	tokens, errors := scanner.scan(
		`
    /*
      /*
          hello world
      */
    */
    +
  `,
	)
	testing.expect(t, len(errors) == 0)
	testing.expect(t, len(tokens) == 2)
	testing.expect(t, tokens[0].type == .PLUS)
	testing.expect(t, tokens[1].type == .EOF)
}
@(test)
block_comment_error :: proc(t: ^testing.T) {
	tokens, errors := scanner.scan(`
    /*
      /*
    */
    +
  `)
	testing.expect(t, len(errors) == 1)
	testing.expect(t, errors[0].type == .Unterminated_Block_Comment)
}
