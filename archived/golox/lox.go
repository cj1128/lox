package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"cjting.me/lox/scanner"
)

type Lox struct {
	env    *Env
	parser *Parser
}

/*----------  Public API  ----------*/

func NewLox() *Lox {
	return &Lox{
		env:    globalEnv,
		parser: NewParser(),
	}
}

func (lox *Lox) Eval(source string) error {
	// scan
	tokens, err := scanner.Scan(source)

	if err != nil {
		return fmt.Errorf("scan error: %v", err)
	}

	// parse
	program, err := lox.parser.Parse(tokens)
	if err != nil {
		return fmt.Errorf("parse error: %v", err)
	}

	if err := lox.interpret(program); err != nil {
		return fmt.Errorf("runtime error: %v", err)
	}

	return nil
}

func (lox *Lox) REPL() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Print("> ")
	for scanner.Scan() {
		str := scanner.Text()

		err := lox.Eval(str)

		// TODO, this is a dirty hack, we need a better way to check
		// whether err is ParseError
		if err != nil && strings.Index(err.Error(), "parse error") == 0 {
			val, e := lox.evalExpression(str)
			if e != nil {
				if strings.Index(e.Error(), "parse error") == 0 {
					fmt.Println(err)
				} else {
					fmt.Println(e)
				}
			} else {
				fmt.Println(val)
			}
		} else if err != nil {
			fmt.Println(err)
		}

		fmt.Print("> ")
	}
}

/*----------  Private Methods  ----------*/
// used by REPL, source should be a whole expression
func (lox *Lox) evalExpression(source string) (val Val, err error) {
	tokens, err := scanner.Scan(source)
	if err != nil {
		err = fmt.Errorf("scan error: %v", err)
		return
	}
	lox.parser.reset(tokens)
	defer func() {
		if e := recover(); e != nil {
			err = fmt.Errorf("%v", e)
			return
		}
	}()
	expr := lox.parser.Expression()
	if lox.parser.isAtEnd() {
		val = expr.Eval(lox.env)
	} else {
		err = fmt.Errorf("not a expression")
	}
	return
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
