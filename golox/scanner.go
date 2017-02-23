/*
* @Author: CJ Ting
* @Date: 2017-01-18 11:06:37
* @Email: fatelovely1128@gmail.com
 */

// Scanner implements
package main

import (
	"fmt"
	"strconv"

	"github.com/pkg/errors"
)

type Scanner struct {
	source []rune
	start  int
	next   int
	line   int
}

func NewScanner(source string) *Scanner {
	return &Scanner{
		source: []rune(source),
		line:   1,
	}
}

func (s *Scanner) isAtEnd() bool {
	return s.next == len(s.source)
}

func (s *Scanner) advance() rune {
	s.next++
	return s.source[s.next-1]
}

func (s *Scanner) currentStr() string {
	return string(s.source[s.start:s.next])
}

func (s *Scanner) peek() rune {
	return s.peekN(1)
}

// return 0x00 if index out of bound
func (s *Scanner) peekN(n int) rune {
	i := s.next + n - 1
	if i >= len(s.source) {
		return '\x00'
	}
	return s.source[i]
}

func (s *Scanner) newToken(typ TokenType, literal interface{}) *Token {
	return newToken(
		typ,
		s.currentStr(),
		literal,
		s.line,
	)
}

func (s *Scanner) ScanTokens() (tokens []*Token, err error) {
	for !s.isAtEnd() {
		s.start = s.next
		token, e := s.scanToken()
		if e != nil {
			err = errors.Wrap(e, fmt.Sprintf("line %d", s.line))
			return
		}
		if token != nil {
			tokens = append(tokens, token)
		}
	}

	tokens = append(
		tokens,
		// can't use s.newToken, it would use last character as lexeme
		newToken(EOF, "", nil, s.line),
	)
	return
}

func (s *Scanner) scanString() (token *Token, err error) {
	for s.peek() != '"' && !s.isAtEnd() {
		if s.peek() == '\n' {
			s.line++
		}
		s.advance()
	}
	if s.isAtEnd() {
		err = fmt.Errorf("Unterminated string")
		return
	}

	// swallow the closing "
	s.advance()

	token = s.newToken(STRING, string(s.source[s.start+1:s.next-1]))
	return
}

func (s *Scanner) scanNumber() (token *Token, err error) {
	for isDigit(s.peek()) {
		s.advance()
	}

	if s.peek() == '.' && isDigit(s.peekN(2)) {
		s.advance()
		for isDigit(s.peek()) {
			s.advance()
		}
	}

	n, e := strconv.ParseFloat(s.currentStr(), 64)
	if e != nil {
		err = errors.Wrap(e, "Can't parse number")
	} else {
		token = s.newToken(NUMBER, n)
	}
	return
}

func (s *Scanner) scanIdentifier() *Token {
	for isAlphaNumeric(s.peek()) {
		s.advance()
	}
	identifier := s.currentStr()
	typ := KeywordToken[identifier]
	if typ == "" {
		return s.newToken(IDENTIFIER, nil)
	} else {
		return s.newToken(typ, nil)
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

func (s *Scanner) scanToken() (token *Token, err error) {
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
	case '\r':
	case '\t':
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
			err = fmt.Errorf("Unexpected character")
		}
	}
	return
}
