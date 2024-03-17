package ast

import "core:fmt"
import "core:mem"
import "core:testing"

import "../lexer"

test_to_string :: proc(t: ^testing.T) {
	// Program: program
	program := new_node(Program)
	defer delete_program(program)

	// Ident: "myVar"
	name_ident := new_node(Ident)
	name_ident.token = lexer.Token {
		type    = lexer.IDENT,
		literal = "myVar",
	}
	name_ident.value = "myVar"

	// Ident: "anotherVar"
	value_ident := new_node(Ident)
	value_ident.token = lexer.Token {
		type    = lexer.IDENT,
		literal = "anotherVar",
	}
	value_ident.value = "anotherVar"

	// Let_Stmt
	// name: "myVar"
	// value: "anotherVar"
	let := new_node(Let_Stmt)
	let.token = lexer.Token {
		type    = lexer.LET,
		literal = "let",
	}
	let.name = name_ident
	let.value = value_ident

	program.statements = [dynamic]^Stmt{let}

	s := to_string(program)
	defer delete(s)
	if s != "let myVar = anotherVar;" {
		testing.errorf(t, "to_string(program) wrong. got=%q", s)
	}
}

run_test :: proc(t: ^testing.T, msg: string, func: proc(t: ^testing.T)) {
	fmt.println(msg)
	func(t)
}

@(test)
test_parser_main :: proc(t: ^testing.T) {

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	run_test(t, "[RUN] test_to_string", test_to_string)
}
