/*
* @Author: CJ Ting
* @Date: 2017-01-18 11:04:55
* @Email: fatelovely1128@gmail.com
 */

package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"os"
)

type Lox struct{}

func (lox *Lox) runFile(path string) {
	buf, err := ioutil.ReadFile(path)
	if err != nil {
		lox.Fatal(err)
	}
	err = lox.run(string(buf))
	if err != nil {
		lox.Fatal(err)
	}
}

func (lox *Lox) runPrompt() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Print("> ")
	for scanner.Scan() {
		str := scanner.Text()
		err := lox.run(str)
		if err != nil {
			fmt.Println(err)
		}
		fmt.Print("> ")
	}
}

func (lox *Lox) Fatal(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}

func (lox *Lox) run(source string) error {
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
