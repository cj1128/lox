package main

import "fmt"

type Lox struct{}

func (lox *Lox) Eval(source string) error {
	scanner := NewScanner(source)
	tokens, err := scanner.ScanTokens()
	parser := NewParser(tokens)
	expr, err := parser.Parse()

	if err != nil {
		return err
	}

	fmt.Println(expr.print())

	return nil
}
