package object

import "core:fmt"

Environment :: struct {
	store: map[string]^Object,
	outer: ^Environment,
}

new_enviroment :: proc() -> ^Environment {
	e := new(Environment)
	return e
}

delete_enviroment :: proc(e: ^Environment) {

	delete(e.store)
	free(e.outer)

	free(e)
}

new_enclosed_environment :: proc(outer: ^Environment) -> ^Environment {
	env := new_enviroment()
	env.outer = outer
	return env
}

get :: proc(e: ^Environment, name: string) -> (^Object, bool) {
	obj, ok := e.store[name]
	if !ok && e.outer != nil {
		obj, ok = get(e.outer, name)
	}
	return obj, ok
}

set :: proc(e: ^Environment, name: string, val: ^Object) -> ^Object {
	e.store[name] = val
	return val
}
