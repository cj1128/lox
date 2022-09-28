package scanner

import (
	"fmt"

	"github.com/pkg/errors"
)

type scanner struct {
	source []rune
	start  int
	next   int
	line   int
}

func Scan(source string) ([]*Token, error) {
	scanner := scanner{}
	return scanner.scan(source)
}

func (s *scanner) scan(source string) ([]*Token, error) {
	s.reset(source)
	var tokens []*Token

	for !s.isAtEnd() {
		s.start = s.next
		token, err := s.scanToken()

		if err != nil {
			return nil, fmt.Errorf("line %d, %v", s.line, err)
		}

		// nil means no meaningful token, like all space
		if token != nil {
			tokens = append(tokens, token)
		}
	}

	tokens = append(
		tokens,
		NewToken(EOF, "", nil, s.line),
	)

	return tokens, nil
}

func (s *scanner) reset(source string) {
	s.source = []rune(source)
	s.start = 0
	s.next = 0
	s.line = 1
}

func (s *scanner) isAtEnd() bool {
	return s.next == len(s.source)
}

func (s *scanner) advance() rune {
	s.next++
	return s.source[s.next-1]
}

func (s *scanner) currentStr() string {
	return string(s.source[s.start:s.next])
}

func (s *scanner) peek() rune {
	return s.peekN(1)
}

// return 0x00 if index out of bound
func (s *scanner) peekN(n int) rune {
	i := s.next + n - 1

	if i >= len(s.source) {
		return 0
	}

	return s.source[i]
}

func (s *scanner) newToken(typ TokenType, literal interface{}) *Token {
	return NewToken(
		typ,
		s.currentStr(),
		literal,
		s.line,
	)
}

func (s *scanner) scanString() (*Token, error) {
	for s.peek() != '"' && !s.isAtEnd() {
		if s.peek() == '\n' {
			s.line++
		}
		s.advance()
	}

	if s.isAtEnd() {
		return nil, fmt.Errorf("unterminated string")
	}

	// swallow the closing "
	s.advance()

	return s.newToken(STRING, parseStringLiteral(string(s.source[s.start+1:s.next-1]))), nil
}

func (s *scanner) scanNumber() (*Token, error) {
	for isDigit(s.peek()) {
		s.advance()
	}

	if s.peek() == '.' && isDigit(s.peekN(2)) {
		s.advance()
		for isDigit(s.peek()) {
			s.advance()
		}
	}

	n, e := parseNumberLiteral((s.currentStr()))

	if e != nil {
		return nil, errors.Wrap(e, "invalild number literal")
	}

	return s.newToken(NUMBER, n), nil
}

func (s *scanner) scanIdentifier() *Token {
	for isAlphaNumeric(s.peek()) {
		s.advance()
	}
	identifier := s.currentStr()
	typ := keyworkdTokens[identifier]
	if typ == "" {
		return s.newToken(IDENTIFIER, nil)
	} else {
		return s.newToken(typ, nil)
	}
}

// support nested block comment
func (s *scanner) scanBlockComment() {
	for !s.isAtEnd() {
		// nested block comment
		if s.peek() == '/' && s.peekN(2) == '*' {
			s.advance()
			s.advance()
			s.scanBlockComment()
		}

		// terminate block comment
		if s.peek() == '*' && s.peekN(2) == '/' {
			s.advance()
			s.advance()
			break
		}

		if s.peek() == '\n' {
			s.line++
		}

		s.advance()
	}
}

func (s *scanner) skipSpaces() {
	if !s.isAtEnd() && isSpace(s.peek()) {
		s.advance()
	}
}

func (s *scanner) scanToken() (*Token, error) {
	var token *Token

	c := s.advance()

	switch c {
	case '(':
		token = s.newToken(LEFT_PAREN, nil)
	case ')':
		token = s.newToken(RIGHT_PAREN, nil)
	case '{':
		token = s.newToken(LEFT_BRACE, nil)
	case '}':
		token = s.newToken(RIGHT_BRACE, nil)
	case ',':
		token = s.newToken(COMMA, nil)
	case '-':
		token = s.newToken(MINUS, nil)
	case '+':
		token = s.newToken(PLUS, nil)
	case ';':
		token = s.newToken(SEMICOLON, nil)
	case '*':
		token = s.newToken(STAR, nil)
	case '.':
		token = s.newToken(DOT, nil)

	case '!':
		if s.peek() == '=' {
			s.advance()
			token = s.newToken(BANG_EQUAL, nil)
		} else {
			token = s.newToken(BANG, nil)
		}
	case '=':
		if s.peek() == '=' {
			s.advance()
			token = s.newToken(EQUAL_EQUAL, nil)
		} else {
			token = s.newToken(EQUAL, nil)
		}
	case '<':
		if s.peek() == '=' {
			s.advance()
			token = s.newToken(LESS_EQUAL, nil)
		} else {
			token = s.newToken(LESS, nil)
		}
	case '>':
		if s.peek() == '=' {
			s.advance()
			token = s.newToken(GREATER_EQUAL, nil)
		} else {
			token = s.newToken(GREATER, nil)
		}
	case '/':
		// line comment
		if s.peek() == '/' {
			for !s.isAtEnd() && s.peek() != '\n' {
				s.advance()
			}
			// block comment
		} else if s.peek() == '*' {
			s.advance() // consume *
			s.scanBlockComment()
		} else {
			token = s.newToken(SLASH, nil)
		}

	case ' ':
		fallthrough
	case '\r':
		fallthrough
	case '\t':
		s.skipSpaces()

	case '\n':
		s.line++

	case '"':
		return s.scanString()

	default:
		if isDigit(c) {
			return s.scanNumber()
		} else if isAlpha(c) {
			token = s.scanIdentifier()
		} else {
			return nil, fmt.Errorf("unexpected token: %c", c)
		}
	}

	return token, nil
}

func isDigit(r rune) bool {
	return r >= '0' && r <= '9'
}

func isAlpha(c rune) bool {
	return (c >= 'a' && c <= 'z') ||
		(c >= 'A' && c <= 'Z') ||
		c == '_'
}

func isAlphaNumeric(c rune) bool {
	return isAlpha(c) || isDigit(c)
}

func isSpace(c rune) bool {
	return c == ' ' || c == '\t' || c == '\r'
}
