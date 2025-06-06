package lox

import "./parser"
import "./scanner"
import "core:bufio"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

had_error := false

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	_main()

	if len(track.allocation_map) > 0 {
		fmt.println("==== Memory Leak ====")
		for _, v in track.allocation_map {
			fmt.printf("%v Leaked %v bytes: %#v\n", v.location, v.size, v.err)
		}
	}
}


_main :: proc() {
	args := os.args[1:]

	switch len(args) {
	case 0:
		run_prompt()
	case 1:
		run_file(args[0])
	case:
		fmt.eprintln("Usage: olox [script]")
		os.exit(64)
	}
}

run_file :: proc(fp: string) {
	data, err := os.read_entire_file_or_err(fp, context.allocator)
	if err != nil {
		fmt.eprintf("failed to read file %s: %v", fp, err)
		return
	}

	run(string(data))

	if (had_error) {
		os.exit(65)
	}
}

run :: proc(code: string) {
	tokens, errors := scanner.scan(code)
	defer delete(tokens)
	defer delete(errors)

	if len(errors) > 0 {
		fmt.eprintln("failed to scan:")
		for e in errors {
			fmt.eprintf("error: %v\n", e)
		}
		return
	}

	// print tokens
	{
		fmt.println("#### tokens ####")
		for t in tokens {
			fmt.println("--", t)
		}
	}

	parsed := parser.parse(tokens[:])
	defer parser.destroy(parsed)
	if len(parsed.errors) > 0 {
		fmt.eprintln("failed to parse:")
		for e in parsed.errors {
			fmt.eprintf("error: %v\n", e)
		}
		return
	}

	// print AST
	{
		fmt.println("#### AST ####")
		str := parser.pp(parsed.ast)
		defer delete(str)
		fmt.println(str)
	}

	// evaluate expresion
	v, err := evaluate(parsed.ast)
	if err != nil {
		fmt.eprintf("error: %v\n", err)
		delete(err.(string))
	} else {
		fmt.println("#### Evaluate ####")
		str, ok := v.(string)
		if ok {
			fmt.printf("%q\n", str)
		} else {
			fmt.println(v)
		}
	}
}

run_prompt :: proc() {
	r: bufio.Reader
	bufio.reader_init(&r, os.stream_from_handle(os.stdin))
	defer bufio.reader_destroy(&r)

	for {
		fmt.print("> ")
		line, err := bufio.reader_read_string(&r, '\n', context.allocator)
		if err != nil {
			fmt.eprintf("failed to read line: %v", err)
			return
		}
		defer delete(line, context.allocator)

		line = strings.trim_right(line, "\n")

		if line == "" {
			break
		}

		run(line)
	}
}
