package evaluator

import "core:fmt"
import "core:mem"
import "core:testing"

import "../ast"
import "../lexer"
import "../object"
import "../parser"

Types1 :: union {
	i64,
}

test_eval :: proc(input: string) -> ^object.Object {
	l := lexer.new_lexer(input)
	defer lexer.delete_lexer(l)

	p := parser.new_parser(l)
	defer parser.delete_parser(p)

	program := parser.parse_program(p)
	defer ast.delete_program(program)

	env := object.new_enviroment()
	defer object.delete_enviroment(env)

	return eval(program, env)
}

test_integer_object :: proc(t: ^testing.T, obj: ^object.Object, expected: i64) -> bool {
	result, ok := obj.derived.(^object.Integer)
	if !ok {
		testing.errorf(t, "object is not Integer. got=%T (%v)", obj, obj.derived)
		return false
	}
	if result.value != expected {
		testing.errorf(t, "object has wrong value. got=%d, want=%d", result.value, expected)
		return false
	}
	return true
}

test_boolean_object :: proc(t: ^testing.T, obj: ^object.Object, expected: bool) -> bool {
	result, ok := obj.derived.(^object.Boolean)
	if !ok {
		testing.errorf(t, "object is not Boolean. got=%T (%v)", obj, obj.derived)
		return false
	}
	if result.value != expected {
		testing.errorf(t, "object has wrong value. got=%t, want=%t", result.value, expected)
		return false
	}
	return true
}

test_null_object :: proc(t: ^testing.T, obj: ^object.Object) -> bool {
	if obj != NULL {
		testing.errorf(t, "object is not NULL. got=%T (%v)", obj, obj.derived)
		return false
	}
	return true
}

// tests

test_eval_integer_expr :: proc(t: ^testing.T) {
	tests := []struct {
		input:    string,
		expected: i64,
	} {
		{"5", 5},
		{"10", 10},
		{"-5", -5},
		{"-10", -10},
		{"5 + 5 + 5 + 5 - 10", 10},
		{"2 * 2 * 2 * 2 * 2", 32},
		{"-50 + 100 + -50", 0},
		{"5 * 2 + 10", 20},
		{"5 + 2 * 10", 25},
		{"20 + 2 * -10", 0},
		{"50 / 2 * 2 + 10", 60},
		{"2 * (5 + 10)", 30},
		{"3 * 3 * 3 + 10", 37},
		{"3 * (3 * 3) + 10", 37},
		{"(5 + 10 * 2 + 15 / 3) * 2 + -10", 50},
	}

	for tt in tests {
		evaluated := test_eval(tt.input)
		test_integer_object(t, evaluated, tt.expected)
	}
}

test_eval_boolean_expr :: proc(t: ^testing.T) {
	tests := []struct {
		input:    string,
		expected: bool,
	} {
		{"true", true},
		{"false", false},
		{"1 < 2", true},
		{"1 > 2", false},
		{"1 < 1", false},
		{"1 > 1", false},
		{"1 == 1", true},
		{"1 != 1", false},
		{"1 == 2", false},
		{"1 != 2", true},
		{"true == true", true},
		{"false == false", true},
		{"true == false", false},
		{"true != false", true},
		{"false != true", true},
		{"(1 < 2) == true", true},
		{"(1 < 2) == false", false},
		{"(1 > 2) == true", false},
		{"(1 > 2) == false", true},
	}

	for tt in tests {
		evaluated := test_eval(tt.input)
		test_boolean_object(t, evaluated, tt.expected)
	}
}


test_bang_operator :: proc(t: ^testing.T) {
	tests := []struct {
		input:    string,
		expected: bool,
	} {
		{"!true", false},
		{"!false", true},
		{"!5", false},
		{"!!true", true},
		{"!!false", false},
		{"!!5", true},
	}

	for tt in tests {
		evaluated := test_eval(tt.input)
		test_boolean_object(t, evaluated, tt.expected)
	}
}

test_if_else_expr :: proc(t: ^testing.T) {
	tests := []struct {
		input:    string,
		expected: Types1,
	} {
		{"if (true) { 10 }", 10},
		{"if (false) { 10 }", nil},
		{"if (1) { 10 }", 10},
		{"if (1 < 2) { 10 }", 10},
		{"if (1 > 2) { 10 }", nil},
		{"if (1 > 2) { 10 } else { 20 }", 20},
		{"if (1 < 2) { 10 } else { 20 }", 10},
	}
	for tt in tests {
		evaluated := test_eval(tt.input)
		switch e in tt.expected {
		case i64:
			test_integer_object(t, evaluated, tt.expected.(i64))
		case:
			test_null_object(t, evaluated)
		}
	}
}

test_return_stmts :: proc(t: ^testing.T) {
	tests := []struct {
		input:    string,
		expected: i64,
	} {
		{"return 10;", 10},
		{"return 10; 9;", 10},
		{"return 2 * 5; 9;", 10},
		{"9; return 2 * 5; 9;", 10},
		{`
		if (10 > 1) {
		  if (10 > 1) {
		    return 10;
		  }

		  return 1;
		}
		`, 10},
	}

	for tt in tests {
		evaluated := test_eval(tt.input)
		test_integer_object(t, evaluated, tt.expected)
	}
}

test_error_handling :: proc(t: ^testing.T) {
	tests := []struct {
		input:        string,
		expected_msg: string,
	} {
		{"5 + true;", "type mismatch: INTEGER + BOOLEAN"},
		{"5 + true; 5;", "type mismatch: INTEGER + BOOLEAN"},
		{"-true", "unknown operator: -BOOLEAN"},
		{"true + false;", "unknown operator: BOOLEAN + BOOLEAN"},
		{"5; true + false; 5", "unknown operator: BOOLEAN + BOOLEAN"},
		{"if (10 > 1) { true + false; }", "unknown operator: BOOLEAN + BOOLEAN"},
		 {
			`
		if (10 > 1) {
		  if (10 > 1) {
		    return true + false;
		  }

		  return 1;
		}
		`,
			"unknown operator: BOOLEAN + BOOLEAN",
		},
		{"foobar", "identifier not found: foobar"},
	}

	for tt in tests {
		evaluated := test_eval(tt.input)

		err_obj, ok := evaluated.derived.(^object.Error)
		if !ok {
			testing.errorf(
				t,
				"no error object returned. got=%T (%v)",
				evaluated,
				evaluated.derived,
			)
			continue
		}

		if err_obj.message != tt.expected_msg {
			testing.errorf(
				t,
				"wrong error message. expected=%q, got=%q",
				tt.expected_msg,
				err_obj.message,
			)
		}
	}
}

test_let_stmts :: proc(t: ^testing.T) {
	tests := []struct {
		input:    string,
		expected: i64,
	} {
		{"let a = 5; a;", 5},
		{"let a = 5 * 6; a;", 30},
		{"let a = 5; let b = a; b;", 5},
		{"let a = 5; let b = a; let c = a + b + 5; c;", 15},
		{"let a = 9; let b = 1; let c = a + b; a; b; c;", 10},
	}

	for tt in tests {
		evaluated := test_eval(tt.input)
		// defer object.delete_object()
		test_integer_object(t, evaluated, tt.expected)
	}
}

run_test :: proc(t: ^testing.T, msg: string, func: proc(t: ^testing.T)) {
	fmt.println(msg)
	func(t)
}

@(test)
test_evaluator_main :: proc(t: ^testing.T) {

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
					fmt.eprintf("%p\n", entry.memory)
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

	new_eval()
	defer delete_eval()

	run_test(t, "[RUN] test_eval_integer_expr", test_eval_integer_expr)
	run_test(t, "[RUN] test_eval_boolean_expr", test_eval_boolean_expr)
	run_test(t, "[RUN] test_bang_operator", test_bang_operator)
	run_test(t, "[RUN] test_if_else_expr", test_if_else_expr)
	run_test(t, "[RUN] test_return_stmts", test_return_stmts)
	run_test(t, "[RUN] test_error_handling", test_error_handling)
	run_test(t, "[RUN] test_let_stmts", test_let_stmts)
}
