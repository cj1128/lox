/*
* @Author: CJ Ting
* @Date: 2017-01-18 09:59:10
* @Email: fatelovely1128@gmail.com
 */

package main

import (
	"log"
	"os"
)

func main() {
	args := os.Args
	if len(args) > 2 {
		log.Println("Usage: golox [script]")
		os.Exit(1)
	}

	lox := &Lox{}

	if len(args) == 2 {
		lox.runFile(args[1])
	} else {
		lox.runPrompt()
	}
}
