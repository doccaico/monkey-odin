package parser

import "core:fmt"
import "core:strings"

import "../ast"
import "../lexer"

precedence :: enum {
	LOWEST,
	EQUALS, // ==
	LESSGREATER, // > or <
	SUM, // +
	PRODUCT, // *
	PREFIX, // -X or !X
	CALL, // my_function(X)
}

prefix_parse_fn :: proc(_: ^Parser) -> ^ast.Expr
infix_parse_fn :: proc(_: ^Parser, _: ^ast.Expr) -> ^ast.Expr

// prefix_parse_fn :: proc() -> ^ast.Expr
// infix_parse_fn :: proc(_: ^ast.Expr) -> ^ast.Expr

register_prefix :: proc(p: ^Parser, token_type: lexer.TokenType, fn: prefix_parse_fn) {
	p.prefix_parse_fns[token_type] = fn
}

register_infix :: proc(p: ^Parser, token_type: lexer.TokenType, fn: infix_parse_fn) {
	p.infix_parse_fns[token_type] = fn
}

Parser :: struct {
	l:                ^lexer.Lexer,
	errors:           [dynamic]string,
	cur_token:        lexer.Token,
	peek_token:       lexer.Token,
	prefix_parse_fns: map[lexer.TokenType]prefix_parse_fn,
	infix_parse_fns:  map[lexer.TokenType]infix_parse_fn,
}

new_parser :: proc(l: ^lexer.Lexer) -> ^Parser {

	p := new(Parser)
	p.l = l
	p.errors = make([dynamic]string)

	// Read two tokens, so cur_token and peek_token are both set
	next_token(p)
	next_token(p)

	p.prefix_parse_fns[lexer.IDENT] = parse_ident

	return p
}

delete_parser :: proc(p: ^Parser) {
	delete(p.errors)
	delete(p.prefix_parse_fns)
	delete(p.infix_parse_fns)
	free(p)
}

errors :: proc(p: ^Parser) -> [dynamic]string {
	return p.errors
}

peek_error :: proc(p: ^Parser, t: lexer.TokenType) {
	msg := fmt.tprintf("expected next token to be (%s), got (%s) instead", t, p.peek_token.type)
	append(&p.errors, msg)
}

next_token :: proc(p: ^Parser) {
	p.cur_token = p.peek_token
	p.peek_token = lexer.next_token(p.l)
}

parse_program :: proc(p: ^Parser) -> ^ast.Program {
	program := ast.new_node(ast.Program)
	program.statements = make([dynamic]^ast.Stmt)

	for p.cur_token.type != lexer.EOF {
		stmt := parse_statement(p)
		if stmt != nil {
			append(&program.statements, stmt)
		}
		next_token(p)
	}

	return program
}

parse_statement :: proc(p: ^Parser) -> ^ast.Stmt {
	switch p.cur_token.type {
	case lexer.LET:
		return parse_let_stmt(p)
	case lexer.RETURN:
		return parse_return_stmt(p)
	case:
		return parser_expr_stmt(p)
	}
}

parse_let_stmt :: proc(p: ^Parser) -> ^ast.Stmt {
	let := ast.new_node(ast.Let_Stmt)
	let.token = p.cur_token

	if !expect_peek(p, lexer.IDENT) {
		return nil
	}

	let.name = ast.new_node(ast.Ident)
	let.name.token = p.cur_token
	let.name.value = p.cur_token.literal

	if !expect_peek(p, lexer.ASSIGN) {
		return nil
	}

	// TODO: We're skipping the expressions until we
	// encounter a semicolon
	for !cur_token_is(p, lexer.SEMICOLON) {
		next_token(p)
	}

	return let
}

parse_return_stmt :: proc(p: ^Parser) -> ^ast.Stmt {
	ret := ast.new_node(ast.Return_Stmt)
	ret.token = p.cur_token

	next_token(p)

	// TODO: We're skipping the expressions until we
	// encounter a semicolon
	for !cur_token_is(p, lexer.SEMICOLON) {
		next_token(p)
	}

	return ret
}

parser_expr_stmt :: proc(p: ^Parser) -> ^ast.Expr_Stmt {
	stmt := ast.new_node(ast.Expr_Stmt)
	stmt.token = p.cur_token

	stmt.expr = parse_expr(p, .LOWEST)

	if peek_token_is(p, lexer.SEMICOLON) {
		next_token(p)
	}

	return stmt
}

parse_expr :: proc(p: ^Parser, prec: precedence) -> ^ast.Expr {
	prefix := p.prefix_parse_fns[p.cur_token.type]
	if prefix == nil {
		return nil
	}
	left_expr := prefix(p)
	return left_expr
}

parse_ident :: proc(p: ^Parser) -> ^ast.Expr {
	expr := ast.new_node(ast.Ident)
	expr.token = p.cur_token
	expr.value = p.cur_token.literal

	return expr
}

cur_token_is :: proc(p: ^Parser, t: lexer.TokenType) -> bool {
	return p.cur_token.type == t
}

peek_token_is :: proc(p: ^Parser, t: lexer.TokenType) -> bool {
	return p.peek_token.type == t
}

expect_peek :: proc(p: ^Parser, t: lexer.TokenType) -> bool {
	if peek_token_is(p, t) {
		next_token(p)
		return true
	} else {
		peek_error(p, t)
		return false
	}
}
