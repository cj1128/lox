/*
* @Author: CJ Ting
* @Date: 2017-01-18 11:06:37
* @Email: fatelovely1128@gmail.com
 */

package main

import "strconv"

type Scanner struct {
	lox     *Lox
	source  []rune
	start   int
	current int
	line    int
}

func newScanner(lox *Lox, source string) *Scanner {
	return &Scanner{
		lox:    lox,
		source: []rune(source),
		line:   1,
	}
}

func (s *Scanner) isAtEnd() bool {
	return s.current == len(s.source)
}

func (s *Scanner) advance() rune {
	s.current++
	return s.source[s.current-1]
}

func (s *Scanner) char() rune {
	return s.source[s.current]
}

func (s *Scanner) peek() rune {
	return s.peekN(1)
}

func (s *Scanner) peekN(n int) rune {
	i := s.current + n - 1
	if i >= len(s.source) {
		return '\x00'
	}
	return s.source[i]
}

func (s *Scanner) newToken(typ TokenType, literal interface{}) *Token {
	return newToken(
		typ,
		string(s.source[s.start:s.current]),
		literal,
		s.line,
	)
}

func (s *Scanner) scanTokens() []*Token {
	var tokens []*Token

	for !s.isAtEnd() {
		s.start = s.current
		token := s.scanToken()
		if token != nil {
			tokens = append(tokens, token)
		}
	}

	tokens = append(
		tokens,
		newToken(EOF, "", nil, s.line),
	)

	return tokens
}

func (s *Scanner) scanString() *Token {
	for s.peek() != '"' && !s.isAtEnd() {
		if s.peek() == '\n' {
			s.line++
		}
		s.advance()
	}
	if s.isAtEnd() {
		s.lox.err(s.line, "Unterminated string.")
		return nil
	}

	// swallow the closing "
	s.advance()

	return s.newToken(STRING, string(s.source[s.start:s.current]))
}

func (s *Scanner) isDigit(r rune) bool {
	return r >= '0' && r <= '9'
}

func (s *Scanner) scanNumber() *Token {
	for s.isDigit(s.peek()) {
		s.advance()
	}

	if s.peek() == '.' && s.isDigit(s.peekN(2)) {
		s.advance()
		for s.isDigit(s.peek()) {
			s.advance()
		}
	}

	n, _ := strconv.ParseFloat(string(s.source[s.start:s.current]), 64)
	return s.newToken(NUMBER, n)
}

func (s *Scanner) isAlpha(c rune) bool {
	return (c >= 'a' && c <= 'z') ||
		(c >= 'A' && c <= 'Z') ||
		c == '_'
}

func (s *Scanner) isAlphaNumeric(c rune) bool {
	return s.isAlpha(c) || s.isDigit(c)
}

func (s *Scanner) scanIdentifier() *Token {
	for s.isAlphaNumeric(s.peek()) {
		s.advance()
	}
	id := string(s.source[s.start:s.current])
	typ := KeywordToken[id]
	if typ == "" {
		return s.newToken(IDENTIFIER, id)
	} else {
		return s.newToken(typ, id)
	}
}

func (s *Scanner) scanBlockComment() {
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

		s.advance()
	}
}

func (s *Scanner) scanToken() (token *Token) {
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
		} else if s.peek() == '*' { // block comment
			s.advance() // consume *
			s.scanBlockComment()
		} else {
			token = s.newToken(SLASH, nil)
		}
	case ' ':
	case '\r':
	case '\t':
	case '\n':
		s.line++
	case '"':
		token = s.scanString()
	default:
		if s.isDigit(c) {
			token = s.scanNumber()
		} else if s.isAlpha(c) {
			token = s.scanIdentifier()
		} else {
			s.lox.err(s.line, "Unexpected character.")
		}
	}
	return
}
