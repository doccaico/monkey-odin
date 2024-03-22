package parser

import "core:fmt"
import "core:strconv"
// import "core:strings"

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

precedences := map[lexer.TokenType]precedence {
	lexer.EQ       = .EQUALS,
	lexer.NOT_EQ   = .EQUALS,
	lexer.LT       = .LESSGREATER,
	lexer.GT       = .LESSGREATER,
	lexer.PLUS     = .SUM,
	lexer.MINUS    = .SUM,
	lexer.SLASH    = .PRODUCT,
	lexer.ASTERISK = .PRODUCT,
	lexer.LPAREN   = .CALL,
}


prefix_parse_fn :: proc(_: ^Parser) -> ^ast.Expr
infix_parse_fn :: proc(_: ^Parser, _: ^ast.Expr) -> ^ast.Expr

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

	register_prefix(p, lexer.IDENT, parse_ident)
	register_prefix(p, lexer.INT, parse_int_literal)
	register_prefix(p, lexer.BANG, parse_prefix_expr)
	register_prefix(p, lexer.MINUS, parse_prefix_expr)
	register_prefix(p, lexer.TRUE, parse_bool_literal)
	register_prefix(p, lexer.FALSE, parse_bool_literal)
	register_prefix(p, lexer.LPAREN, parse_grouped_expr)
	register_prefix(p, lexer.IF, parse_if_expr)
	register_prefix(p, lexer.FUNCTION, parse_function_literal)
	register_prefix(p, lexer.STRING, parse_string_literal)

	register_infix(p, lexer.PLUS, parse_infix_expr)
	register_infix(p, lexer.MINUS, parse_infix_expr)
	register_infix(p, lexer.SLASH, parse_infix_expr)
	register_infix(p, lexer.ASTERISK, parse_infix_expr)
	register_infix(p, lexer.EQ, parse_infix_expr)
	register_infix(p, lexer.NOT_EQ, parse_infix_expr)
	register_infix(p, lexer.LT, parse_infix_expr)
	register_infix(p, lexer.GT, parse_infix_expr)
	register_infix(p, lexer.LPAREN, parse_call_expr)

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
	// program.statements = make([dynamic]^ast.Stmt)

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
	// case lexer.LET:
	// v:= parse_let_stmt(p)
	// if v != nil {
	// return v
	// } else {
	// 	return nil
	// }
	case lexer.RETURN:
		return parse_return_stmt(p)
	case:
		return parser_expr_stmt(p)
	}
}

parse_let_stmt :: proc(p: ^Parser) -> ^ast.Stmt {
	stmt := ast.new_node(ast.Let_Stmt)
	stmt.token = p.cur_token

	if !expect_peek(p, lexer.IDENT) {
		return nil
	}

	stmt.name = ast.new_node(ast.Ident)
	stmt.name.token = p.cur_token
	stmt.name.value = p.cur_token.literal

	if !expect_peek(p, lexer.ASSIGN) {
		free(stmt.name)
		free(stmt)
		return nil
	}

	next_token(p)

	stmt.value = parse_expr(p, .LOWEST)

	if peek_token_is(p, lexer.SEMICOLON) {
		next_token(p)
	}

	return stmt
}

parse_return_stmt :: proc(p: ^Parser) -> ^ast.Stmt {
	stmt := ast.new_node(ast.Return_Stmt)
	stmt.token = p.cur_token

	next_token(p)

	stmt.return_value = parse_expr(p, .LOWEST)

	if peek_token_is(p, lexer.SEMICOLON) {
		next_token(p)
	}

	return stmt
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

no_prefix_parse_fn_error :: proc(p: ^Parser, t: lexer.TokenType) {
	msg := fmt.tprintf("no prefix parse function for '%s' found", t)
	append(&p.errors, msg)
}

parse_expr :: proc(p: ^Parser, prec: precedence) -> ^ast.Expr {
	prefix := p.prefix_parse_fns[p.cur_token.type]

	if prefix == nil {
		no_prefix_parse_fn_error(p, p.cur_token.type)
		return nil
	}
	left_expr := prefix(p)

	for !peek_token_is(p, lexer.SEMICOLON) && prec < peek_precedence(p) {
		infix := p.infix_parse_fns[p.peek_token.type]
		if infix == nil {
			return left_expr
		}

		next_token(p)

		left_expr = infix(p, left_expr)
	}

	return left_expr
}

parse_ident :: proc(p: ^Parser) -> ^ast.Expr {
	expr := ast.new_node(ast.Ident)
	expr.token = p.cur_token
	expr.value = p.cur_token.literal

	return expr
}

parse_int_literal :: proc(p: ^Parser) -> ^ast.Expr {
	expr := ast.new_node(ast.Int_Literal)
	expr.token = p.cur_token

	value, ok := strconv.parse_i64(p.cur_token.literal)
	if !ok {
		msg := fmt.tprintf("could not parse %q as integer", p.cur_token.literal)
		append(&p.errors, msg)
		return nil
	}

	expr.value = value

	return expr
}

parse_prefix_expr :: proc(p: ^Parser) -> ^ast.Expr {
	expr := ast.new_node(ast.Prefix_Expr)
	expr.token = p.cur_token
	expr.operator = p.cur_token.literal

	next_token(p)

	expr.right = parse_expr(p, .PREFIX)

	return expr
}

parse_infix_expr :: proc(p: ^Parser, left: ^ast.Expr) -> ^ast.Expr {
	expr := ast.new_node(ast.Infix_Expr)
	expr.token = p.cur_token
	expr.operator = p.cur_token.literal
	expr.left = left

	prec := cur_precedence(p)
	next_token(p)
	expr.right = parse_expr(p, prec)

	return expr
}

parse_bool_literal :: proc(p: ^Parser) -> ^ast.Expr {
	expr := ast.new_node(ast.Bool_Literal)
	expr.token = p.cur_token
	expr.value = cur_token_is(p, lexer.TRUE)

	return expr
}

parse_grouped_expr :: proc(p: ^Parser) -> ^ast.Expr {
	next_token(p)

	expr := parse_expr(p, .LOWEST)

	if !expect_peek(p, lexer.RPAREN) {
		return nil
	}

	return expr
}

parse_if_expr :: proc(p: ^Parser) -> ^ast.Expr {
	expr := ast.new_node(ast.If_Expr)
	expr.token = p.cur_token

	if !expect_peek(p, lexer.LPAREN) {
		return nil
	}

	next_token(p)
	expr.condition = parse_expr(p, .LOWEST)

	if !expect_peek(p, lexer.RPAREN) {
		return nil
	}

	if !expect_peek(p, lexer.LBRACE) {
		return nil
	}

	expr.consequence = parse_block_stmt(p)

	if peek_token_is(p, lexer.ELSE) {
		next_token(p)

		if !expect_peek(p, lexer.LBRACE) {
			return nil
		}

		expr.alternative = parse_block_stmt(p)
	}

	return expr
}

parse_block_stmt :: proc(p: ^Parser) -> ^ast.Block_Stmt {
	block := ast.new_node(ast.Block_Stmt)
	block.token = p.cur_token

	next_token(p)

	for !cur_token_is(p, lexer.RBRACE) {
		stmt := parse_statement(p)
		if stmt != nil {
			append(&block.statements, stmt)
		}
		next_token(p)
	}

	return block
}

parse_function_literal :: proc(p: ^Parser) -> ^ast.Expr {
	expr := ast.new_node(ast.Function_Literal)
	expr.token = p.cur_token

	if !expect_peek(p, lexer.LPAREN) {
		return nil
	}

	expr.parameters = parse_function_parameters(p)

	if !expect_peek(p, lexer.LBRACE) {
		return nil
	}

	expr.body = parse_block_stmt(p)

	return expr
}

parse_function_parameters :: proc(p: ^Parser) -> [dynamic]^ast.Ident {
	identifiers: [dynamic]^ast.Ident

	if peek_token_is(p, lexer.RPAREN) {
		next_token(p)
		return identifiers
	}

	next_token(p)

	ident := ast.new_node(ast.Ident)
	ident.token = p.cur_token
	ident.value = p.cur_token.literal
	append(&identifiers, ident)

	for peek_token_is(p, lexer.COMMA) {
		next_token(p)
		next_token(p)
		ident := ast.new_node(ast.Ident)
		ident.token = p.cur_token
		ident.value = p.cur_token.literal
		append(&identifiers, ident)
	}

	if !expect_peek(p, lexer.RPAREN) {
		return nil
	}

	return identifiers
}

parse_call_expr :: proc(p: ^Parser, function: ^ast.Expr) -> ^ast.Expr {
	expr := ast.new_node(ast.Call_Expr)
	expr.token = p.cur_token
	expr.function = function
	expr.arguments = parse_call_arguments(p)

	return expr
}

parse_call_arguments :: proc(p: ^Parser) -> [dynamic]^ast.Expr {
	args: [dynamic]^ast.Expr

	if peek_token_is(p, lexer.RPAREN) {
		next_token(p)
		return args
	}

	next_token(p)
	append(&args, parse_expr(p, .LOWEST))

	for peek_token_is(p, lexer.COMMA) {
		next_token(p)
		next_token(p)
		append(&args, parse_expr(p, .LOWEST))
	}

	if !expect_peek(p, lexer.RPAREN) {
		return nil
	}

	return args
}

parse_string_literal :: proc(p: ^Parser) -> ^ast.Expr {
	expr := ast.new_node(ast.String_Literal)
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

peek_precedence :: proc(p: ^Parser) -> precedence {
	if prec, ok := precedences[p.peek_token.type]; ok {
		return prec
	}
	return .LOWEST
}

cur_precedence :: proc(p: ^Parser) -> precedence {
	if prec, ok := precedences[p.cur_token.type]; ok {
		return prec
	}
	return .LOWEST
}
