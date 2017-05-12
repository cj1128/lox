package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"os"

	"gopkg.in/alecthomas/kingpin.v2"
)

var (
	scriptPath string
)

func parseFlags() {
	kingpin.Arg("script", "specify script path, if none get input from stdin").StringVar(&scriptPath)
	kingpin.CommandLine.HelpFlag.Short('h')
	kingpin.Parse()
}

func main() {
	parseFlags()
	lox := &Lox{}
	if scriptPath == "" {
		scanner := bufio.NewScanner(os.Stdin)
		fmt.Print("> ")
		for scanner.Scan() {
			str := scanner.Text()
			if err := lox.Eval(str); err != nil {
				fmt.Println(err)
			}
			fmt.Print("> ")
		}
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
