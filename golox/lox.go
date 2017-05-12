package main

import (
	"fmt"
)

type Lox struct{}

func (lox *Lox) Eval(source string) error {
	scanner := NewScanner(source)
	tokens, err := scanner.ScanTokens()
	if err != nil {
		return err
	}
	for _, token := range tokens {
		fmt.Println(token)
	}
	return nil
}
