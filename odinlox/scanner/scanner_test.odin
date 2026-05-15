package scanner

import scanner "."
import "core:fmt"
import "core:testing"

@(test)
basic_scanner :: proc(t: ^testing.T) {
	result := scanner.scan(
		`( ) { } , . - + ; / *
  ! ? : != = == > >= < <=
  identifier "string" 1.234000
  and class else fun for if nil or print return super this true false var while
`,
	)
	defer scanner.destroy(&result)
	testing.expect(t, len(result.errors) == 0)

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
		{type = .QUESTION},
		{type = .COLON},
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

	for exp, i in expected {
		token := result.tokens[i]

		testing.expect(
			t,
			token.type == exp.type,
			fmt.tprintf("expected token type %v, got %v", exp.type, token.type),
		)

		if exp.lexeme != "" {
			testing.expect(
				t,
				token.lexeme == exp.lexeme,
				fmt.tprintf("expected token lexeme %q, got %q", exp.lexeme, token.lexeme),
			)
		}

		if exp.literal != nil {
			testing.expect(
				t,
				token.literal == exp.literal,
				fmt.tprintf("expected token literal %v, got %v", exp.literal, token.literal),
			)
		}
	}
}

@(test)
error_unterminated_string :: proc(t: ^testing.T) {
	result := scanner.scan(`"unterminated string`)
	defer scanner.destroy(&result)
	testing.expect(t, len(result.tokens) == 1) // EOF
	testing.expect(t, result.tokens[0].type == .EOF)

	testing.expect(t, len(result.errors) == 1)
	testing.expect(t, result.errors[0].type == .Unterminated_String)
}

@(test)
line_comment :: proc(t: ^testing.T) {
	result := scanner.scan(`
    // this is a comment
    +
  `)
	defer scanner.destroy(&result)
	testing.expect(t, len(result.errors) == 0)
	testing.expect(t, len(result.tokens) == 2)
	testing.expect(t, result.tokens[0].type == .PLUS)
	testing.expect(t, result.tokens[1].type == .EOF)
}

@(test)
block_comment_ok :: proc(t: ^testing.T) {
	result := scanner.scan(`
    /*
      /*
          hello world
      */
    */
    +
  `)
	defer scanner.destroy(&result)
	testing.expect(t, len(result.errors) == 0)
	testing.expect(t, len(result.tokens) == 2)
	testing.expect(t, result.tokens[0].type == .PLUS)
	testing.expect(t, result.tokens[1].type == .EOF)
}
@(test)
error_unterminated_block_comment :: proc(t: ^testing.T) {
	result := scanner.scan(`
    /*
      /*
    */
    +
  `)
	defer scanner.destroy(&result)
	testing.expect(t, len(result.errors) == 1)
	testing.expect(t, result.errors[0].type == .Unterminated_Block_Comment)
}

@(test)
error_unexpected_char :: proc(t: ^testing.T) {
	result := scanner.scan(`@`)
	defer scanner.destroy(&result)
	testing.expect(t, len(result.tokens) == 1) // EOF
	testing.expect(t, result.tokens[0].type == .EOF)
	testing.expect(t, len(result.errors) == 1)
	testing.expect(t, result.errors[0].type == .Unexpected_Char)
	testing.expect(t, result.errors[0].char == '@')
}

@(test)
error_multiple :: proc(t: ^testing.T) {
	result := scanner.scan(`@ + #`)
	defer scanner.destroy(&result)
	testing.expect(t, len(result.errors) == 2)
	testing.expect(t, result.errors[0].type == .Unexpected_Char)
	testing.expect(t, result.errors[0].char == '@')
	testing.expect(t, result.errors[1].type == .Unexpected_Char)
	testing.expect(t, result.errors[1].char == '#')
	// valid tokens still scanned
	testing.expect(t, result.tokens[0].type == .PLUS)
	testing.expect(t, result.tokens[1].type == .EOF)
}

@(test)
token_line :: proc(t: ^testing.T) {
	result := scanner.scan(`var x = 1
print x
"hello"
`)
	defer scanner.destroy(&result)
	testing.expect(t, len(result.errors) == 0)

	Expected :: struct {
		type: scanner.Token_Type,
		line: int,
	}

	expected := []Expected {
		{.VAR, 1},
		{.IDENTIFIER, 1},
		{.EQUAL, 1},
		{.NUMBER, 1},
		{.PRINT, 2},
		{.IDENTIFIER, 2},
		{.STRING, 3},
		{.EOF, 4},
	}

	testing.expect(
		t,
		len(result.tokens) == len(expected),
		fmt.tprintf("expected %d tokens, got %d", len(expected), len(result.tokens)),
	)

	for exp, i in expected {
		token := result.tokens[i]
		testing.expect(
			t,
			token.type == exp.type,
			fmt.tprintf("token %d: expected type %v, got %v", i, exp.type, token.type),
		)
		testing.expect(
			t,
			token.line == exp.line,
			fmt.tprintf(
				"token %d (%v): expected line %d, got %d",
				i,
				exp.type,
				exp.line,
				token.line,
			),
		)
	}
}
