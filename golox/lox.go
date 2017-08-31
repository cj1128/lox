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

	fmt.Println(expr.print())

	return nil
}
