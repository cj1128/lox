/*
* @Author: CJ Ting
* @Date: 2017-01-18 09:59:10
* @Email: fatelovely1128@gmail.com
 */

// Lox interpreter
package main

import "gopkg.in/alecthomas/kingpin.v2"

var (
	script string
)

func parseFlags() {
	kingpin.Arg("script", "script to run").StringVar(&script)
	kingpin.Parse()
}

func main() {
	parseFlags()

	lox := &Lox{}
	if script == "" {
		lox.runPrompt()
	} else {
		lox.runFile(script)
	}
}
