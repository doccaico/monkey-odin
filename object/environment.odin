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
	// for a, b in e.store {
	// 	fmt.println(a, b)
	// }
	// fmt.println(e)
	// delete(e.outer.store)
	// free(e.outer.outer)

	delete(e.store)
	free(e.outer)

	// fmt.println(">>>")
	// fmt.println(e.outer)
	// fmt.println(e.outer.store)
	// fmt.println(e.outer.outer) // nil
	// fmt.println("<<<")
	// delete(e.outer.store)
	// free(e.outer.outer)
	// free(e.outer.outer)
	// delete_outer(e.outer)
	free(e)
}

new_enclosed_environment :: proc(outer: ^Environment) -> ^Environment {
	env := new_enviroment()
	env.outer = outer
	// fmt.printf("Heelo world: %p\n", env)
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
