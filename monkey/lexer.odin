package monkey

// import "core:fmt"

Lexer :: struct {
	input:         string,
	position:      int,
	read_position: int,
	ch:            byte,
}


new_lexer :: proc(input: string) -> ^Lexer {
	l := new(Lexer)
	l.input = input
	read_char(l)
	return l
}

delete_lexer :: proc(lexer: ^Lexer) {
	free(lexer)
}

read_char :: proc(l: ^Lexer) {
	if l.read_position >= len(l.input) {
		l.ch = 0
	} else {
		l.ch = l.input[l.read_position]
	}
	l.position = l.read_position
	l.read_position += 1
}

next_token :: proc(l: ^Lexer) -> Token {
	tok: Token

	skip_whitespace(l)

	switch l.ch {
	case '=':
		tok = new_token(ASSIGN, l.ch)
	case ';':
		tok = new_token(SEMICOLON, l.ch)
	case '(':
		tok = new_token(LPAREN, l.ch)
	case ')':
		tok = new_token(RPAREN, l.ch)
	case ',':
		tok = new_token(COMMA, l.ch)
	case '+':
		tok = new_token(PLUS, l.ch)
	case '{':
		tok = new_token(LBRACE, l.ch)
	case '}':
		tok = new_token(RBRACE, l.ch)
	case 0:
		tok.literal = ""
		tok.type = EOF
	case:
		if is_letter(l.ch) {
			tok.literal = read_identifier(l)
			tok.type = lookup_ident(tok.literal)
			return tok
		} else if is_digit(l.ch) {
			tok.literal = read_number(l)
			tok.type = INT
			return tok
		} else {
			tok = new_token(ILLEGAL, l.ch)
		}
	}

	read_char(l)
	return tok
}

read_identifier :: proc(l: ^Lexer) -> string {
	position := l.position
	for is_letter(l.ch) {
		read_char(l)
	}
	return l.input[position:l.position]
}

read_number :: proc(l: ^Lexer) -> string {
	position := l.position
	for is_digit(l.ch) {
		read_char(l)
	}
	return l.input[position:l.position]
}

is_letter :: proc(ch: byte) -> bool {
	return 'a' <= ch && ch <= 'z' || 'A' <= ch && ch <= 'Z' || ch == '_'
}

is_digit :: proc(ch: byte) -> bool {
	return '0' <= ch && ch <= '9'
}

skip_whitespace :: proc(l: ^Lexer) {
	for l.ch == ' ' || l.ch == '\t' || l.ch == '\n' || l.ch == '\r' {
		read_char(l)
	}
}
