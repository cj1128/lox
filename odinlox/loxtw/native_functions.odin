package loxtw
import "core:time"

import "../parser"

Native_Function_Clock :: Callable {
	arity = 0,
	call = proc(env: ^Env, args: []Value) -> (Value, Evaluate_Error) {
		nano := time.to_unix_nanoseconds(time.now())
		return f64(nano) / 1e9, nil
	},
}
