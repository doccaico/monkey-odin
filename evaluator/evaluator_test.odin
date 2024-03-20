package evaluator

// import "core:bytes"
import "core:fmt"
import "core:mem"
// import "core:mem"
import "core:testing"

import "../ast"
import "../lexer"
import "../object"
import "../parser"

test_eval_integer_expr :: proc(t: ^testing.T) {
	tests := []struct {
		input:    string,
		expected: i64,
	}{{"5", 5}, {"10", 10}}

	for tt in tests {
		evaluated := test_eval(tt.input)
		defer object.delete_object(evaluated)
		test_integer_object(t, evaluated, tt.expected)
	}
}

test_eval :: proc(input: string) -> ^object.Object {
	l := lexer.new_lexer(input)
	defer lexer.delete_lexer(l)

	p := parser.new_parser(l)
	defer parser.delete_parser(p)

	program := parser.parse_program(p)
	defer ast.delete_program(program)

	return eval(program)
}

test_integer_object :: proc(t: ^testing.T, obj: ^object.Object, expected: i64) -> bool {
	result, ok := obj.derived.(^object.Integer)
	if !ok {
		testing.errorf(t, "object is not Integer. got=%T (%+v)", obj, obj)
		return false
	}
	if result.value != expected {
		testing.errorf(t, "object has wrong value. got=%d, want=%d", result.value, expected)
		return false
	}
	return true
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
					// fmt.eprintf("%p\n", entry.memory)
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

	run_test(t, "[RUN] test_eval_integer_expr", test_eval_integer_expr)
}
