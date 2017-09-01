package main

import "fmt"

type Lox struct{}

func (lox *Lox) Eval(source string) error {
	scanner := NewScanner(source)

	tokens, err := scanner.ScanTokens()
	if err != nil {
		return fmt.Errorf("scan error: %v", err)
	}

	parser := NewParser(tokens)
	expr, err := parser.Parse()
	if err != nil {
		return fmt.Errorf("parse error: %v", err)
	}

	val, err := lox.interpreter(expr)
	if err != nil {
		return fmt.Errorf("runtime error: %v", err)
	}

	fmt.Println(val)

	return nil
}

func (lox *Lox) interpreter(expr Expr) (val Val, err error) {
	defer func() {
		if e := recover(); e != nil {
			if re, ok := e.(*RuntimeError); ok {
				err = re
			} else {
				panic(e)
			}
		}
	}()
	val = expr.Eval()
	return
}
