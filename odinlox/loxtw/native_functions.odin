package loxtw
import "core:time"

import "../parser"

_clock :: proc(env: ^Env, args: []Value) -> (Value, Runtime_Error) {
	nano := time.to_unix_nanoseconds(time.now())
	return f64(nano) / 1e9, nil
}

native_function_clock := Callable {
	arity = 0,
	variant = Native_Function{call = _clock},
}
