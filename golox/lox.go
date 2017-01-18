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
	"log"
	"os"
)

type Lox struct{}

var errorf = func(str string, items ...interface{}) {
	fmt.Fprintf(os.Stderr, str, items...)
}

func (l *Lox) runFile(path string) {
	buf, err := ioutil.ReadFile(path)
	if err != nil {
		log.Fatal(err)
	}
	l.run(string(buf))
}

func (l *Lox) err(line int, msg string) {
	errorf("[line %d] Error: %s\n", line, msg)
}

func (l *Lox) runPrompt() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Print("> ")
	for scanner.Scan() {
		str := scanner.Text()
		l.run(str)
		fmt.Print("> ")
	}
}

func (l *Lox) run(source string) {
	scanner := newScanner(l, source)
	for _, token := range scanner.scanTokens() {
		fmt.Println(token)
	}
}
