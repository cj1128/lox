package main

import "time"

// global env

var globalEnv = NewEnv(nil)

func init() {
	globalEnv.Define("clock", NewFunction(0, func(_ *Env, _ []Val) Val {
		return time.Now().Unix()
	}))
}
