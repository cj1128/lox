package main

import (
	"fmt"
	"io/ioutil"
	"os"

	"gopkg.in/alecthomas/kingpin.v2"
)

var (
	scriptPath string
)

func parseFlags() {
	kingpin.Arg("script", "specify script path, if none, start REPL").StringVar(&scriptPath)
	kingpin.CommandLine.HelpFlag.Short('h')
	kingpin.Parse()
}

func main() {
	parseFlags()

	lox := NewLox()

	if scriptPath == "" {
		lox.REPL()
	} else {
		buf, err := ioutil.ReadFile(scriptPath)
		if err != nil {
			fmt.Printf("could not open file: %v\n", err)
			os.Exit(1)
		}
		if err := lox.Eval(string(buf)); err != nil {
			fmt.Println(err)
		}
	}
}
