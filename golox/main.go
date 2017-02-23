/*
* @Author: CJ Ting
* @Date: 2017-01-18 09:59:10
* @Email: fatelovely1128@gmail.com
 */

// Lox interpreter
package main

import "gopkg.in/alecthomas/kingpin.v2"

var (
	scriptPath string
)

func parseFlags() {
	kingpin.Arg("script", "specify script path").StringVar(&scriptPath)
	kingpin.Parse()
}

func main() {
	parseFlags()

	lox := &Lox{}
	if scriptPath == "" {
		lox.runPrompt()
	} else {
		lox.runFile(scriptPath)
	}
}
