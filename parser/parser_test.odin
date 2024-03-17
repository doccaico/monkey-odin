package parser

import "core:fmt"
import "core:mem"
import "core:testing"

import "../ast"
import "../lexer"
import "../parser"

check_parser_errors :: proc(t: ^testing.T, p: ^Parser) {
	errors := errors(p)
	if len(errors) == 0 {
		return
	}

	testing.errorf(t, "parser has %d errors", len(errors))
	for msg in errors {
		testing.errorf(t, "parser error: %q", msg)
	}
	testing.fail_now(t)
}

test_let_stmts :: proc(t: ^testing.T) {
	input := `let x = 5;
	let y = 10;
	let foobar = 838383;
	`

	l := lexer.new_lexer(input)
	defer lexer.delete_lexer(l)

	p := new_parser(l)
	defer delete_parser(p)

	program := parse_program(p)
	defer ast.delete_program(program)

	check_parser_errors(t, p)

	if program == nil {
		fmt.panicf("ParseProgram() returned nil")
	}
	if len(program.statements) != 3 {
		fmt.panicf(
			"program.statements does not contain 3 statements. got=%d",
			len(program.statements),
		)
	}

	tests := []struct {
		expected_ident: string,
	}{{"x"}, {"y"}, {"foobar"}}

	for tt, i in tests {
		stmt := program.statements[i]
		if !test_let_stmt(t, stmt, tt.expected_ident) {
			return
		}
	}
}

test_let_stmt :: proc(t: ^testing.T, s: ^ast.Stmt, name: string) -> bool {

	if ast.token_literal(s.expr_base) != "let" {
		testing.errorf(
			t,
			"ast.token_literal(s.expr_base) not 'let'. got=%q",
			ast.token_literal(s.expr_base),
		)
		return false
	}

	let_stmt, ok := s.derived.(^ast.Let_Stmt)
	if !ok {
		testing.errorf(t, "s.derived not ^ast.Let_Stmt. got=%T", s)
		return false
	}

	if let_stmt.name.value != name {
		testing.errorf(t, "let_stmt.name.value not '%s'. got=%s", name, let_stmt.name.value)
		return false
	}

	if ast.token_literal(let_stmt.name) != name {
		testing.errorf(t, "ast.token_literal(let_stmt.name) not '%s'. got=%s", name, let_stmt.name)
		return false
	}

	return true
}

test_return_stmts :: proc(t: ^testing.T) {
	input := `
    return 5;
    return 10;
    return 993322;
    `

	l := lexer.new_lexer(input)
	defer lexer.delete_lexer(l)

	p := new_parser(l)
	defer delete_parser(p)

	program := parse_program(p)
	defer ast.delete_program(program)

	check_parser_errors(t, p)

	if len(program.statements) != 3 {
		fmt.panicf(
			"program.statements does not contain 3 statements. got=%d",
			len(program.statements),
		)
	}

	for s in program.statements {
		return_stmt, ok := s.derived.(^ast.Return_Stmt)
		if !ok {
			testing.errorf(t, "s.derived not ^ast.Return_Stmt. got=%T", s)
			continue
		}
		if ast.token_literal(return_stmt) != "return" {
			testing.errorf(
				t,
				"ast.token_literal(return_stmt) not 'return'. got=%q",
				ast.token_literal(return_stmt),
			)
		}
	}
}

test_ident_expr :: proc(t: ^testing.T) {
	input := "foobar;"

	l := lexer.new_lexer(input)
	defer lexer.delete_lexer(l)

	p := new_parser(l)
	defer delete_parser(p)

	program := parse_program(p)
	defer ast.delete_program(program)

	check_parser_errors(t, p)

	if len(program.statements) != 1 {
		fmt.panicf(
			"program.statements does not enough statements. got=%d",
			len(program.statements),
		)
	}
	stmt, ok_stmt := program.statements[0].derived.(^ast.Expr_Stmt)
	if !ok_stmt {
		fmt.panicf(
			"program.statements[0].derived is not ^ast.Expr_Stmt. got=%T",
			program.statements[0],
		)
	}

	if stmt.expr == nil {
		panic("stmt.expr == nil; use 'useregister_prefix'")
	}

	ident, ok_ident := stmt.expr.derived.(^ast.Ident)
	if !ok_ident {
		fmt.panicf("exp not ^ast.Ident. got=%T", stmt.expr)
	}
	if ident.value != "foobar" {
		testing.errorf(t, "ident.value not %s. got=%s", "foobar", ident.value)
	}
	if ast.token_literal(ident) != "foobar" {
		testing.errorf(
			t,
			"ast.token_literal(ident) not %s. got=%s",
			"foobar",
			ast.token_literal(ident),
		)
	}
}

test_int_literal_expr :: proc(t: ^testing.T) {
	input := "5;"

	l := lexer.new_lexer(input)
	defer lexer.delete_lexer(l)

	p := new_parser(l)
	defer delete_parser(p)

	program := parse_program(p)
	defer ast.delete_program(program)

	check_parser_errors(t, p)

	if len(program.statements) != 1 {
		fmt.panicf(
			"program.statements does not enough statements. got=%d",
			len(program.statements),
		)
	}
	stmt, ok_stmt := program.statements[0].derived.(^ast.Expr_Stmt)
	if !ok_stmt {
		fmt.panicf(
			"program.statements[0].derived is not ^ast.Expr_Stmt. got=%T",
			program.statements[0],
		)
	}

	if stmt.expr == nil {
		panic("stmt.expr == nil; use 'useregister_prefix'")
	}

	literal, ok_literal := stmt.expr.derived.(^ast.Int_Literal)
	if !ok_literal {
		fmt.panicf("exp not ^ast.Int_Literal. got=%T", stmt.expr)
	}
	if literal.value != 5 {
		testing.errorf(t, "literal.value not %d. got=%d", 5, literal.value)
	}
	if ast.token_literal(literal) != "5" {
		testing.errorf(
			t,
			"ast.token_literal(literal) not %s. got=%s",
			"5",
			ast.token_literal(literal),
		)
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

	run_test(t, "[RUN] test_let_stmts", test_let_stmts)
	run_test(t, "[RUN] test_return_stmts", test_return_stmts)
	run_test(t, "[RUN] test_ident_expr", test_ident_expr)
	run_test(t, "[RUN] test_int_literal_expr", test_int_literal_expr)
}
