package loxtw

import "../parser"
import "../scanner"
import "core:bufio"
import "core:fmt"
import "core:log"
import "core:mem"
import vmem "core:mem/virtual"
import "core:os"
import "core:strings"

global_env := new_env()
main :: proc() {
	env_define(global_env, "clock", native_function_clock)

	log_level := log.Level.Info
	if os.get_env("DEBUG") != "" {
		log_level = log.Level.Debug
	}
	context.logger = log.create_console_logger(log_level, {.Level, .Terminal_Color})

	// disable mem-tracking now
	when false {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
	}

	_main()

	when false {
		if len(track.allocation_map) > 0 {
			fmt.println("==== Memory Leak ====")
			for _, v in track.allocation_map {
				fmt.printf("%v Leaked %v bytes: %#v\n", v.location, v.size, v.err)
			}
		}
	}
}


_main :: proc() {
	args := os.args[1:]

	switch len(args) {
	case 0:
		run_prompt()
	case 1:
		if code := run_file(args[0]); code != 0 {
			os.exit(code)
		}
	case:
		fmt.println("Usage: olox [script]")
		os.exit(64)
	}
}

run_file :: proc(fp: string) -> (exit_code: int) {
	data, err := os.read_entire_file_or_err(fp)
	if err != nil {
		fmt.eprintf("failed to read file %s: %v", fp, err)
		return
	}
	defer delete(data)

	exit_code = run(string(data)) ? 0 : 65

	return exit_code
}

run :: proc(code: string, is_repl := false) -> (ok: bool) {
	ok = true
	tokens, errors := scanner.scan(code)
	// defer delete(tokens)
	// defer delete(errors)

	{
		log.debug("#### Scanner ####")

		if len(errors) > 0 {
			ok = false
			fmt.eprintln("failed to scan:")
			for e in errors {
				fmt.eprintf("-- error: %v\n", e)
			}
			return
		}

		// print tokens
		for t in tokens {
			log.debug("-- token", t)
		}
	}

	log.debug("#### Parser ####")

	parsed := parser.parse(tokens[:], try_parse_as_expr = is_repl)
	// defer parser.destroy(parsed)

	if len(parsed.errors) > 0 {
		ok = false
		fmt.eprintln("parse errors:")
		for e in parsed.errors {
			fmt.eprintf("-- error: %v\n", e)
		}
		return
	}
	if len(parsed.warnings) > 0 {
		fmt.eprintln("parse warnings:")
		for e in parsed.warnings {
			fmt.eprintf("-- warning: %v\n", e)
		}
		return
	}

	is_expr := parsed.expr != nil

	if is_expr {
		pp_str := parser.pp_expr(parsed.expr)
		defer delete(pp_str)
		log.debugf("-- expr %s parsed", pp_str)
	} else {
		log.debugf("-- %d statements parsed", len(parsed.statements))
	}

	// Resolve
	resolve_result: ^Resolve_Result
	if !is_expr {
		log.debug("#### Resolver ####")
		resolve_result = resolve(parsed.statements[:])
		for e in resolve_result.errors {
			fmt.eprintf("-- error: %v\n", e)
		}

		// skip execution
		if len(resolve_result.errors) > 0 {
			return false
		}
	}

	// evaluate statements/expressions
	// arena: mem.Dynamic_Arena
	// mem.dynamic_arena_init(&arena)
	// arena_alloc := mem.dynamic_arena_allocator(&arena)
	// defer mem.dynamic_arena_destroy(&arena)
	// context.allocator = arena_alloc
	{
		if resolve_result != nil {
			global_env.locals = resolve_result.locals
		}

		if is_expr {
			log.debug("#### Evaluate Expression ####")
			value, err := evaluate(global_env, parsed.expr)
			if err != nil {
				ok = false
				fmt.eprintf("-- error: %v\n", err)
			} else {
				buf: [128]byte
				str := value_to_string(value, buf[:], quote_string = true)
				fmt.println(str)
			}
		} else {
			log.debug("#### Execute Statement ####")
			for stmt in parsed.statements {
				pp_str := parser.pp(stmt)
				defer delete(pp_str)
				log.debugf("-- stmt: %s", pp_str)
				if err := execute(global_env, stmt); err != nil {
					ok = false
					fmt.eprintf("-- error: %v\n", err)
				}
				// fmt.println("global env", global_env)
			}
		}
	}

	return
}

run_prompt :: proc() {
	r: bufio.Reader
	bufio.reader_init(&r, os.stream_from_handle(os.stdin))
	defer bufio.reader_destroy(&r)

	for {
		fmt.print("> ")
		line, err := bufio.reader_read_string(&r, '\n')
		if err != nil {
			fmt.printf("failed to read line: %v", err)
			return
		}
		// defer delete(line)

		line = strings.trim_right(line, "\n")

		if line == "" {
			break
		}

		run(line, is_repl = true)
	}
}
