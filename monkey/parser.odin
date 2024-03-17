package monkey

Parser :: struct {
	l:          ^Lexer,
	cur_token:  Token,
	peek_token: Token,
}

new_parser :: proc(l: ^Lexer) -> ^Parser {

	p := new(Parser)
	p.l = l

	// Read two tokens, so curToken and peekToken are both set
	parser_next_token(p)
	parser_next_token(p)
	return p
}

delete_parser :: proc(p: ^Parser) {
	free(p)
}

parser_next_token :: proc(p: ^Parser) {
	p.cur_token = p.peek_token
	p.peek_token = next_token(p.l)
}

parse_program :: proc(p: ^Parser) -> ^Program {
	program := new(Program)
	program.statements = make([dynamic]^Stmt)

	for p.cur_token.type != EOF {
		stmt := parse_statement(p)
		if stmt != nil {
			append(&program.statements, stmt)
		}
		parser_next_token(p)
	}

	return program
}

parse_statement :: proc(p: ^Parser) -> ^Stmt {
	switch p.cur_token.type {
	case LET:
		return parse_let_stmt(p)
	case:
		return nil
	}
}

parse_let_stmt :: proc(p: ^Parser) -> ^Stmt {
	return nil
}
