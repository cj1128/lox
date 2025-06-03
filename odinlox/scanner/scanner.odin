#+feature dynamic-literals
package scanner

import "core:fmt"
import "core:strconv"

@(private)
Scanner :: struct {
	// all index are byte-level
	start:   int,
	current: int,
	line:    int,
	source:  string,
	tokens:  [dynamic]Token,
	errors:  [dynamic]Error,
}

Error_Type :: enum u8 {
	Unexpected_Char,
	Unterminated_String,
	Unterminated_Block_Comment,
}

Error :: struct {
	line: int,
	type: Error_Type,
	char: rune,
}

match :: proc(s: ^Scanner, expected: byte) -> bool {
	if s.current >= len(s.source) {
		return false
	}

	if s.source[s.current] != expected {
		return false
	}

	s.current += 1
	return true
}

add_error_unexpected_char :: proc(s: ^Scanner, char: rune) {
	append(&s.errors, Error{line = s.line, type = .Unexpected_Char, char = char})
}

add_error_unterminated_string :: proc(s: ^Scanner) {
	append(&s.errors, Error{line = s.line, type = .Unterminated_String})
}

add_error_unterminated_block_comment :: proc(s: ^Scanner) {
	append(&s.errors, Error{line = s.line, type = .Unterminated_Block_Comment})
}

add_token :: proc(s: ^Scanner, token_type: Token_Type) {
	append(&s.tokens, Token{type = token_type, lexeme = s.source[s.start:s.current]})
}

add_string_token :: proc(s: ^Scanner, literal: string) {
	append(
		&s.tokens,
		Token{type = .STRING, literal = literal, lexeme = s.source[s.start:s.current]},
	)
}

add_number_token :: proc(s: ^Scanner) {
	lexeme := s.source[s.start:s.current]
	value, ok := strconv.parse_f64(lexeme)
	assert(ok)
	append(&s.tokens, Token{type = .NUMBER, lexeme = lexeme, literal = value})
}

KEYWORDS := map[string]Token_Type {
	"and"    = .AND,
	"class"  = .CLASS,
	"else"   = .ELSE,
	"false"  = .FALSE,
	"for"    = .FOR,
	"fun"    = .FUN,
	"if"     = .IF,
	"nil"    = .NIL,
	"or"     = .OR,
	"print"  = .PRINT,
	"return" = .RETURN,
	"super"  = .SUPER,
	"this"   = .THIS,
	"true"   = .TRUE,
	"var"    = .VAR,
	"while"  = .WHILE,
}
add_identifier_token :: proc(s: ^Scanner, lexeme: string) {
	type, ok := KEYWORDS[lexeme]
	if ok {
		add_token(s, type)
	} else {
		append(&s.tokens, Token{type = .IDENTIFIER, lexeme = lexeme})
	}
}

advance :: proc(s: ^Scanner, offset := 1) -> u8 {
	result := s.source[s.current]
	s.current += offset
	return result
}

peek :: proc(s: ^Scanner, offset := 0) -> u8 {
	idx := s.current + offset
	if idx >= len(s.source) {
		return 0
	}
	return s.source[idx]
}
peek_str :: proc(s: ^Scanner, length: int) -> string {
	end_index := min(s.current + length, len(s.source))
	return s.source[s.current:end_index]
}

has_content :: proc(s: ^Scanner) -> bool {
	return s.current < len(s.source)
}

// public api
scan :: proc(source: string, allocator := context.allocator) -> ([dynamic]Token, [dynamic]Error) {
	s := &Scanner{source = source, tokens = make([dynamic]Token), errors = make([dynamic]Error)}

	for has_content(s) {
		s.start = s.current
		char := advance(s)

		switch char {
		//
		case '(':
			add_token(s, .LEFT_PAREN)
		case ')':
			add_token(s, .RIGHT_PAREN)
		case '{':
			add_token(s, .LEFT_BRACE)
		case '}':
			add_token(s, .RIGHT_BRACE)
		case ',':
			add_token(s, .COMMA)
		case '.':
			add_token(s, .DOT)
		case '-':
			add_token(s, .MINUS)
		case '+':
			add_token(s, .PLUS)
		case ';':
			add_token(s, .SEMICOLON)
		case '*':
			add_token(s, .STAR)
		//
		case '!':
			add_token(s, match(s, '=') ? .BANG_EQUAL : .BANG)
		case '=':
			add_token(s, match(s, '=') ? .EQUAL_EQUAL : .EQUAL)
		case '<':
			add_token(s, match(s, '=') ? .LESS_EQUAL : .LESS)
		case '>':
			add_token(s, match(s, '=') ? .GREATER_EQUAL : .GREATER)
		case '/':
			// comment
			if match(s, '/') {
				for has_content(s) && peek(s) != '\n' {
					advance(s)
				}
			} else if match(s, '*') {
				block_comment(s)
			} else {
				add_token(s, .SLASH)
			}
		//
		case ' ':
			break
		case '\r':
			break
		case '\t':
			break
		//
		case '\n':
			s.line += 1
		//
		case '"':
			string_literal(s)
		case:
			switch {
			case is_digit(char):
				number_literal(s)
			case is_alpha_underscore(char):
				identifier(s)
			case:
				add_error_unexpected_char(s, rune(char))
			}
		}
	}

	s.start = s.current
	add_token(s, .EOF)

	return s.tokens, s.errors
}

is_alpha_underscore :: proc(char: u8) -> bool {
	return (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || char == '_'
}

is_alpha_numeric :: proc(char: u8) -> bool {
	return is_alpha_underscore(char) || is_digit(char)
}


identifier :: proc(s: ^Scanner) {
	for is_alpha_numeric(peek(s)) {
		advance(s)
	}

	add_identifier_token(s, s.source[s.start:s.current])
}

is_digit :: proc(char: u8) -> bool {
	return char >= '0' && char <= '9'
}

number_literal :: proc(s: ^Scanner) {
	for is_digit(peek(s)) {
		advance(s)
	}

	if peek(s) == '.' && is_digit(peek(s, 1)) {
		advance(s)

		for is_digit(peek(s)) {
			advance(s)
		}
	}

	add_number_token(s)
}

string_literal :: proc(s: ^Scanner) {
	for has_content(s) && peek(s) != '"' {
		if peek(s) == '\n' {
			s.line += 1
		}
		advance(s)
	}

	if !has_content(s) {
		add_error_unterminated_string(s)
		return
	}

	// consuming the closing `"`
	advance(s)

	add_string_token(s, s.source[s.start + 1:s.current - 1])
}

// supports nesting
block_comment :: proc(s: ^Scanner) {
	level := 1

	for has_content(s) {
		if peek_str(s, 2) == "/*" {
			level += 1
			advance(s, 2)
		} else if peek_str(s, 2) == "*/" {
			level -= 1
			advance(s, 2)
			if level == 0 {
				return
			}
		} else {
			if peek(s) == '\n' {
				s.line += 1
			}
			advance(s)
		}
	}

	if level != 0 {
		add_error_unterminated_block_comment(s)
	}
}
