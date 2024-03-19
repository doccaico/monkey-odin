package parser

import "core:bytes"
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
		panic("stmt.expr == nil; use 'register_prefix'")
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
		panic("stmt.expr == nil; use 'register_prefix'")
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

test_parsing_prefix_expr :: proc(t: ^testing.T) {
	prefix_tests := []struct {
		input:     string,
		operator:  string,
		int_value: i64,
	}{{"!5;", "!", 5}, {"-15;", "-", 15}}

	for tt in prefix_tests {

		l := lexer.new_lexer(tt.input)
		defer lexer.delete_lexer(l)

		p := new_parser(l)
		defer delete_parser(p)

		program := parse_program(p)
		defer ast.delete_program(program)

		check_parser_errors(t, p)

		if len(program.statements) != 1 {
			fmt.panicf(
				"program.statements does not contain %d statements. got=%d",
				1,
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
			panic("stmt.expr == nil; use 'register_prefix'")
		}

		expr, ok_expr := stmt.expr.derived.(^ast.Prefix_Expr)
		if !ok_expr {
			fmt.panicf("stmt is not ^ast.Prefix_Expr. got=%T", stmt.expr)
		}
		if expr.operator != tt.operator {
			fmt.panicf("expr.operator is not '%s'. got=%s", tt.operator, expr.operator)
		}
		if !test_int_literal(t, expr.right, tt.int_value) {
			return
		}
	}
}

test_int_literal :: proc(t: ^testing.T, il: ^ast.Expr, value: i64) -> bool {
	integ, ok := il.derived.(^ast.Int_Literal)
	if !ok {
		testing.errorf(t, "il not ^ast.Int_Literal. got=%T", il)
		return false
	}

	if integ.value != value {
		testing.errorf(t, "integ.value not %d. got=%d", value, integ.value)
		return false
	}

	int_str := fmt.tprintf("%d", value)
	if ast.token_literal(integ) != int_str {
		testing.errorf(
			t,
			"ast.token_literal(integ) not %d. got=%s",
			value,
			ast.token_literal(integ),
		)
		return false
	}

	return true
}

test_parsing_infix_expr :: proc(t: ^testing.T) {
	infix_tests := []struct {
		input:       string,
		left_value:  i64,
		operator:    string,
		right_value: i64,
	} {
		{"5 + 5;", 5, "+", 5},
		{"5 - 5;", 5, "-", 5},
		{"5 * 5;", 5, "*", 5},
		{"5 / 5;", 5, "/", 5},
		{"5 > 5;", 5, ">", 5},
		{"5 < 5;", 5, "<", 5},
		{"5 == 5;", 5, "==", 5},
		{"5 != 5;", 5, "!=", 5},
	}

	for tt in infix_tests {

		l := lexer.new_lexer(tt.input)
		defer lexer.delete_lexer(l)

		p := new_parser(l)
		defer delete_parser(p)

		program := parse_program(p)
		defer ast.delete_program(program)

		check_parser_errors(t, p)

		if len(program.statements) != 1 {
			fmt.panicf(
				"program.statements does not contain %d statements. got=%d",
				1,
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
			panic("stmt.expr == nil; use 'register_infix'")
		}

		expr, ok_expr := stmt.expr.derived.(^ast.Infix_Expr)
		if !ok_expr {
			fmt.panicf("exp is not ^ast.Infix_Expr. got=%T", stmt.expr)
		}
		if !test_int_literal(t, expr.left, tt.left_value) {
			return
		}
		if expr.operator != tt.operator {
			fmt.panicf("expr.operator is not '%s'. got=%s", tt.operator, expr.operator)
		}
		if !test_int_literal(t, expr.right, tt.right_value) {
			return
		}
	}
}

test_operator_precedence_parsing :: proc(t: ^testing.T) {
	infix_tests := []struct {
		input:    string,
		expected: string,
	} {
		{"-a * b", "((-a) * b)"},
		{"!-a", "(!(-a))"},
		{"a + b + c", "((a + b) + c)"},
		{"a + b - c", "((a + b) - c)"},
		{"a * b * c", "((a * b) * c)"},
		{"a * b / c", "((a * b) / c)"},
		{"a + b / c", "(a + (b / c))"},
		{"a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)"},
		{"3 + 4; -5 * 5", "(3 + 4)((-5) * 5)"},
		{"5 > 4 == 3 < 4", "((5 > 4) == (3 < 4))"},
		{"5 < 4 != 3 > 4", "((5 < 4) != (3 > 4))"},
		{"3 + 4 * 5 == 3 * 1 + 4 * 5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"},
		{"true", "true"},
		{"false", "false"},
		{"3 > 5 == false", "((3 > 5) == false)"},
		{"3 < 5 == true", "((3 < 5) == true)"},
		{"1 + (2 + 3) + 4", "((1 + (2 + 3)) + 4)"},
		{"(5 + 5) * 2", "((5 + 5) * 2)"},
		{"2 / (5 + 5)", "(2 / (5 + 5))"},
		{"-(5 + 5)", "(-(5 + 5))"},
		{"!(true == true)", "(!(true == true))"},
		{"a + add(b * c) + d", "((a + add((b * c))) + d)"},
		 {
			"add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
			"add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))",
		},
		{"add(a + b + c * d / f + g)", "add((((a + b) + ((c * d) / f)) + g))"},
		// Original
		// {"a + add(b * c)", "(a + add((b * c)))"},
	}

	for tt in infix_tests {

		l := lexer.new_lexer(tt.input)
		defer lexer.delete_lexer(l)

		p := new_parser(l)
		defer delete_parser(p)

		program := parse_program(p)
		defer ast.delete_program(program)

		check_parser_errors(t, p)

		buf := ast.to_string(program)
		defer bytes.buffer_destroy(&buf)
		actual := bytes.buffer_to_string(&buf)

		if actual != tt.expected {
			testing.errorf(t, "expected=%q, got=%q", tt.expected, actual)
		}
	}
}

test_bool_literal_expr :: proc(t: ^testing.T) {
	tests := []struct {
		input:    string,
		expected: bool,
	}{{"true;", true}, {"false;", false}}

	for tt in tests {

		l := lexer.new_lexer(tt.input)
		defer lexer.delete_lexer(l)

		p := new_parser(l)
		defer delete_parser(p)

		program := parse_program(p)
		defer ast.delete_program(program)

		check_parser_errors(t, p)

		if len(program.statements) != 1 {
			fmt.panicf("program has not enough statements. got=%d", len(program.statements))
		}

		stmt, ok_stmt := program.statements[0].derived.(^ast.Expr_Stmt)
		if !ok_stmt {
			fmt.panicf(
				"program.statements[0].derived is not ^ast.Expr_Stmt. got=%T",
				program.statements[0],
			)
		}

		boolean, ok_boolean := stmt.expr.derived.(^ast.Bool_Literal)
		if !ok_boolean {
			fmt.panicf("exp is not ^ast.Bool_Literal. got=%T", stmt.expr)
		}
		if boolean.value != tt.expected {
			testing.errorf(t, "boolean.value is not =%v, got=%v", tt.expected, boolean.value)
		}
	}
}

test_parsing_infix_expr_bool :: proc(t: ^testing.T) {
	tests := []struct {
		input:       string,
		left_value:  bool,
		operator:    string,
		right_value: bool,
	} {
		{"true == true", true, "==", true},
		{"true != false", true, "!=", false},
		{"false == false", false, "==", false},
	}

	for tt in tests {

		l := lexer.new_lexer(tt.input)
		defer lexer.delete_lexer(l)

		p := new_parser(l)
		defer delete_parser(p)

		program := parse_program(p)
		defer ast.delete_program(program)

		check_parser_errors(t, p)

		if len(program.statements) != 1 {
			fmt.panicf(
				"program.statements does not contain %d statements. got=%d",
				1,
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

		expr, ok_expr := stmt.expr.derived.(^ast.Infix_Expr)
		if !ok_expr {
			fmt.panicf("expr is not ^ast.Infix_Expr. got=%T", stmt.expr)
		}

		{
			boolean, ok_boolean := expr.left.derived.(^ast.Bool_Literal)
			if !ok_boolean {
				fmt.panicf("boolean is not ^ast.Bool_Literal. got=%T", stmt.expr)
			}
			if boolean.value != tt.left_value {
				testing.errorf(t, "boolean.value is not =%v, got=%v", tt.left_value, boolean.value)
			}
		}

		if expr.operator != tt.operator {
			fmt.panicf("expr.operator is not '%s'. got='%s'", tt.operator, expr.operator)
		}

		{
			boolean, ok_boolean := expr.right.derived.(^ast.Bool_Literal)
			if !ok_boolean {
				fmt.panicf("boolean is not ^ast.Bool_Literal. got=%T", stmt.expr)
			}
			if boolean.value != tt.right_value {
				testing.errorf(
					t,
					"boolean.value is not =%v, got=%v",
					tt.right_value,
					boolean.value,
				)
			}
		}
	}
}

test_parsing_prefix_expr_bool :: proc(t: ^testing.T) {
	tests := []struct {
		input:    string,
		operator: string,
		value:    bool,
	}{{"!true;", "!", true}, {"!false;", "!", false}}

	for tt in tests {

		l := lexer.new_lexer(tt.input)
		defer lexer.delete_lexer(l)

		p := new_parser(l)
		defer delete_parser(p)

		program := parse_program(p)
		defer ast.delete_program(program)

		check_parser_errors(t, p)

		if len(program.statements) != 1 {
			fmt.panicf(
				"program.statements does not contain %d statements. got=%d",
				1,
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

		expr, ok_expr := stmt.expr.derived.(^ast.Prefix_Expr)
		if !ok_expr {
			fmt.panicf("stmt is not ^ast.Prefix_Expr. got=%T", stmt.expr)
		}

		if expr.operator != tt.operator {
			fmt.panicf("expr.operator is not '%s'. got=%s", tt.operator, expr.operator)
		}

		boolean, ok_boolean := expr.right.derived.(^ast.Bool_Literal)
		if !ok_boolean {
			fmt.panicf("boolean is not ^ast.Bool_Literal. got=%T", stmt.expr)
		}
		if boolean.value != tt.value {
			testing.errorf(t, "boolean.value is not =%v, got=%v", tt.value, boolean.value)
		}
	}
}

test_if_expr :: proc(t: ^testing.T) {
	input := `if (x < y) { z }`

	l := lexer.new_lexer(input)
	defer lexer.delete_lexer(l)

	p := new_parser(l)
	defer delete_parser(p)

	program := parse_program(p)
	defer ast.delete_program(program)

	check_parser_errors(t, p)

	if len(program.statements) != 1 {
		fmt.panicf(
			"program.Body does not contain %d statements. got=%d",
			1,
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

	expr, ok_expr := stmt.expr.derived.(^ast.If_Expr)
	if !ok_expr {
		fmt.panicf("stmt is not ^ast.If_Expr. got=%T", stmt.expr)
	}

	// start: "x < y"
	{
		expr, ok_expr := expr.condition.derived.(^ast.Infix_Expr)
		if !ok_expr {
			fmt.panicf("expr is not ^ast.Infix_Expr. got=%T", stmt.expr)
		}

		{
			e, ok := expr.left.derived.(^ast.Ident)
			if !ok {
				fmt.panicf("expr.left is not ^ast.Ident. got=%T", expr.left)
			}
			if e.value != "x" {
				testing.errorf(t, "e.value is not =%v, got=%v", "x", e.value)
			}
		}

		if expr.operator != "<" {
			testing.errorf(t, "expr.operator is not '%s'. got='%s'", "<", expr.operator)
		}

		{
			e, ok := expr.right.derived.(^ast.Ident)
			if !ok {
				fmt.panicf("expr.right is not ^ast.Ident. got=%T", expr.right)
			}
			if e.value != "y" {
				testing.errorf(t, "e.value is not =%v, got=%v", "y", e.value)
			}
		}
	} // end: "x < y"

	if len(expr.consequence.statements) != 1 {
		testing.errorf(
			t,
			"consequence is not 1 statements. got=%d\n",
			len(expr.consequence.statements),
		)
	}

	consequence, ok_consequence := expr.consequence.statements[0].derived.(^ast.Expr_Stmt)
	if !ok_consequence {
		fmt.panicf("expr.consequence.statements[0] is not ^ast.Expr_Stmt. got=%T", consequence)
	}

	// start: "z"
	ident, ok_ident := consequence.expr.derived.(^ast.Ident)
	if !ok_ident {
		fmt.panicf("consequence.expr is not ^ast.Ident. got=%T", ident)
	}
	if ident.value != "z" {
		testing.errorf(t, "ident.value is not =%v, got=%v", "z", ident.value)
	} // end: "z"

	if expr.alternative != nil {
		testing.errorf(t, "expr.alternative.statements was not nil.")
	}
}

test_function_literal_parsing :: proc(t: ^testing.T) {
	input := `fn(x, y) { x + y; }`

	l := lexer.new_lexer(input)
	defer lexer.delete_lexer(l)

	p := new_parser(l)
	defer delete_parser(p)

	program := parse_program(p)
	defer ast.delete_program(program)

	check_parser_errors(t, p)

	if len(program.statements) != 1 {
		fmt.panicf(
			"program.Body does not contain %d statements. got=%d",
			1,
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

	func, ok_func := stmt.expr.derived.(^ast.Function_Literal)
	if !ok_func {
		fmt.panicf("stmt is not ^ast.If_Expr. got=%T", stmt.expr)
	}

	if len(func.parameters) != 2 {
		fmt.panicf("function literal parameters wrong. want 2, got=%d\n", len(func.parameters))
	}

	{
		// start: "x"
		ident, ok_ident := func.parameters[0].derived.(^ast.Ident)
		if !ok_ident {
			fmt.panicf("func.parameters[0] is not ^ast.Ident. got=%T", ident)
		}
		if ident.value != "x" {
			testing.errorf(t, "ident.value is not =%v, got=%v", "x", ident.value)
		} // end: "x"
	}

	{
		// start: "y"
		ident, ok_ident := func.parameters[1].derived.(^ast.Ident)
		if !ok_ident {
			fmt.panicf("func.parameters[0] is not ^ast.Ident. got=%T", ident)
		}
		if ident.value != "y" {
			testing.errorf(t, "ident.value is not =%v, got=%v", "y", ident.value)
		} // end: "y"
	}

	if len(func.body.statements) != 1 {
		fmt.panicf(
			"func.body.statements has not 1 statements. got=%d\n",
			len(func.body.statements),
		)
	}

	body_stmt, ok_body_stmt := func.body.statements[0].derived.(^ast.Expr_Stmt)
	if !ok_body_stmt {
		fmt.panicf("function body stmt is not ^ast.Expr_Stmt. got=%T", body_stmt)
	}

	// start: "x + y"
	{
		infix, ok_infix := body_stmt.expr.derived.(^ast.Infix_Expr)
		if !ok_infix {
			fmt.panicf("body_stmt is not ^ast.Infix_Expr. got=%T", body_stmt)
		}

		{
			ident, ok_ident := infix.left.derived.(^ast.Ident)
			if !ok_ident {
				fmt.panicf("infix.left is not ^ast.Ident. got=%T", infix.left)
			}
			if ident.value != "x" {
				testing.errorf(t, "ident.value is not =%v, got=%v", "x", ident.value)
			}
		}

		if infix.operator != "+" {
			testing.errorf(t, "infix.operator is not '%s'. got='%s'", "+", infix.operator)
		}

		{
			ident, ok_ident := infix.right.derived.(^ast.Ident)
			if !ok_ident {
				fmt.panicf("infix.right is not ^ast.Ident. got=%T", infix.right)
			}
			if ident.value != "y" {
				testing.errorf(t, "ident.value is not =%v, got=%v", "y", ident.value)
			}
		}
	} // end: "x + y"
}

test_call_expr_parsing :: proc(t: ^testing.T) {
	input := "add(1, 2 * 3, 4 + 5);"

	l := lexer.new_lexer(input)
	defer lexer.delete_lexer(l)

	p := new_parser(l)
	defer delete_parser(p)

	program := parse_program(p)
	defer ast.delete_program(program)

	check_parser_errors(t, p)

	if len(program.statements) != 1 {
		fmt.panicf(
			"program.statements does not contain %d statements. got=%d",
			1,
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

	expr, ok_expr := stmt.expr.derived.(^ast.Call_Expr)
	if !ok_expr {
		fmt.panicf("stmt.expr is not ^ast.Call_Expr. got=%T", stmt.expr)
	}

	{
		// "add"
		ident, ok_ident := expr.function.derived.(^ast.Ident)
		if !ok_ident {
			fmt.panicf("expr.function is not ^ast.Ident. got=%T", expr.function)
		}
		if ident.value != "add" {
			testing.errorf(t, "ident.value is not =%v, got=%v", "add", ident.value)
		}
	}

	if len(expr.arguments) != 3 {
		fmt.panicf("wrong length of arguments. got=%d", len(expr.arguments))
	}

	{
		// 1
		ilit, ok_ilit := expr.arguments[0].derived.(^ast.Int_Literal)
		if !ok_ilit {
			fmt.panicf("expr.arguments[0] is not ^ast.Int_Literal . got=%T", expr.arguments[0])
		}
		if ilit.value != 1 {
			testing.errorf(t, "ident.value is not =%d, got=%v", 1, ilit.value)
		}
	}

	{
		// 2 * 3
		infix, ok_infix := expr.arguments[1].derived.(^ast.Infix_Expr)
		if !ok_infix {
			fmt.panicf("expr.arguments[1] is not ^ast.Infix_Expr. got=%T", expr.arguments[1])
		}

		{
			ilit, ok_ilit := infix.left.derived.(^ast.Int_Literal)
			if !ok_ilit {
				fmt.panicf("infix.left is not ^ast.Int_Literal. got=%T", infix.left)
			}
			if ilit.value != 2 {
				testing.errorf(t, "ilit.value is not =%d, got=%v", 2, ilit.value)
			}
		}

		if infix.operator != "*" {
			testing.errorf(t, "infix.operator is not '%s'. got='%s'", "*", infix.operator)
		}

		{
			ilit, ok_ilit := infix.right.derived.(^ast.Int_Literal)
			if !ok_ilit {
				fmt.panicf("infix.right is not ^ast.Int_Literal. got=%T", infix.left)
			}
			if ilit.value != 3 {
				testing.errorf(t, "ilit.value is not =%d, got=%v", 3, ilit.value)
			}
		}
	}

	{
		// 4 + 5
		infix, ok_infix := expr.arguments[2].derived.(^ast.Infix_Expr)
		if !ok_infix {
			fmt.panicf("expr.arguments[2] is not ^ast.Infix_Expr. got=%T", expr.arguments[2])
		}

		{
			ilit, ok_ilit := infix.left.derived.(^ast.Int_Literal)
			if !ok_ilit {
				fmt.panicf("infix.left is not ^ast.Int_Literal. got=%T", infix.left)
			}
			if ilit.value != 4 {
				testing.errorf(t, "ilit.value is not =%d, got=%v", 4, ilit.value)
			}
		}

		if infix.operator != "+" {
			testing.errorf(t, "infix.operator is not '%s'. got='%s'", "+", infix.operator)
		}

		{
			ilit, ok_ilit := infix.right.derived.(^ast.Int_Literal)
			if !ok_ilit {
				fmt.panicf("infix.right is not ^ast.Int_Literal. got=%T", infix.right)
			}
			if ilit.value != 5 {
				testing.errorf(t, "ilit.value is not =%d, got=%v", 5, ilit.value)
			}
		}
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

	run_test(t, "[RUN] test_let_stmts", test_let_stmts)
	run_test(t, "[RUN] test_return_stmts", test_return_stmts)
	run_test(t, "[RUN] test_ident_expr", test_ident_expr)
	run_test(t, "[RUN] test_int_literal_expr", test_int_literal_expr)
	run_test(t, "[RUN] test_parsing_prefix_expr", test_parsing_prefix_expr)
	run_test(t, "[RUN] test_parsing_infix_expr", test_parsing_infix_expr)
	run_test(t, "[RUN] test_operator_precedence_parsing", test_operator_precedence_parsing)
	run_test(t, "[RUN] test_bool_literal_expr", test_bool_literal_expr)
	run_test(t, "[RUN] test_parsing_infix_expr_bool", test_parsing_infix_expr_bool)
	run_test(t, "[RUN] test_parsing_prefix_expr_bool", test_parsing_prefix_expr_bool)
	run_test(t, "[RUN] test_if_expr", test_if_expr)
	run_test(t, "[RUN] test_function_literal_parsing", test_function_literal_parsing)
	run_test(t, "[RUN] test_call_expr_parsing", test_call_expr_parsing)
}
