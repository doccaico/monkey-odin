package object

import "core:fmt"

Environment :: struct {
	store: map[string]^Object,
}

new_enviroment :: proc() -> ^Environment {
	return new(Environment)
}

delete_enviroment :: proc(e: ^Environment) {

	delete(e.store)
	free(e)
}

get :: proc(e: ^Environment, name: string) -> (^Object, bool) {
	obj, ok := e.store[name]
	return obj, ok
}

set :: proc(e: ^Environment, name: string, val: ^Object) -> ^Object {
	e.store[name] = val
	return val
}
