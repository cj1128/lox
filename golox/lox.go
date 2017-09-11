package main

import "fmt"

type Lox struct {
	env     *Env
	scanner *Scanner
	parser  *Parser
}

/*----------  Public API  ----------*/

func NewLox() *Lox {
	return &Lox{
		env:     NewEnv(nil),
		scanner: NewScanner(),
		parser:  NewParser(),
	}
}

func (lox *Lox) Eval(source string) error {
	// scan
	tokens, err := lox.scan(source)
	if err != nil {
		return fmt.Errorf("scan error: %v", err)
	}

	// parse
	program, err := lox.parse(tokens)
	if err != nil {
		return fmt.Errorf("parse error: %v", err)
	}

	if err := lox.interpret(program); err != nil {
		return fmt.Errorf("runtime error: %v", err)
	}

	return nil
}

/*----------  Private Methods  ----------*/

func (lox *Lox) scan(source string) ([]*Token, error) {
	return lox.scanner.ScanTokens(source)
}

func (lox *Lox) parse(tokens []*Token) ([]Stmt, error) {
	return lox.parser.Parse(tokens)
}

func (lox *Lox) interpret(program []Stmt) (err error) {
	defer func() {
		if e := recover(); e != nil {
			if re, ok := e.(*RuntimeError); ok {
				err = re
			} else {
				panic(e)
			}
		}
	}()
	for _, stmt := range program {
		stmt.Run(lox.env)
	}
	return
}
