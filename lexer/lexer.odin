package lexer

import "core:fmt"

ILLEGAL :: "ILLEGAL"
EOF :: "EOF"
// Identifiers and lierals
IDENT :: "IDENT"
INT :: "INT"
// Operators
ASSIGN :: "="
PLUS :: "+"
MINUS :: "-"
BANG :: "!"
ASTERISK :: "*"
SLASH :: "/"

LT :: "<"
GT :: ">"
EQ :: "=="
NOT_EQ :: "!="

// Delimiters
COMMA :: ","
SEMICOLON :: ";"
LPAREN :: "("
RPAREN :: ")"
LBRACE :: "{"
RBRACE :: "}"
// COLON :: ":"
// LBRACKET :: "["
// RBRACKET :: "]"

// Keywords
FUNCTION :: "FUNCTION"
LET :: "LET"
TRUE :: "TRUE"
FALSE :: "FALSE"
IF :: "IF"
ELSE :: "ELSE"
RETURN :: "RETURN"

keywords := map[string]TokenType {
	"fn"     = FUNCTION,
	"let"    = LET,
	"true"   = TRUE,
	"false"  = FALSE,
	"if"     = IF,
	"else"   = ELSE,
	"return" = RETURN,
}

TokenType :: distinct string

Token :: struct {
	type:    TokenType,
	literal: string,
}

Lexer :: struct {
	input:         string,
	position:      int,
	read_position: int,
	ch:            byte,
	// tokens:        [dynamic]Token,
	illegals:      [dynamic]string,
}

string_from_byte :: proc(ch: byte) -> string {
	// https://odin-lang.org/docs/overview/#from-u8-to-x
	buf := make([]u8, 1)
	buf[0] = ch
	return transmute(string)buf
}

new_token :: proc(token_type: TokenType, ch: byte) -> Token {
	buf := make([]u8, 1)
	buf[0] = ch
	// https://odin-lang.org/docs/overview/#from-u8-to-x
	return Token{type = token_type, literal = transmute(string)buf}
}

delete_literal :: proc(type: TokenType, literal: string) {
	switch type {
	case EOF, INT, FUNCTION, LET, IDENT, TRUE, FALSE, IF, ELSE, RETURN, EQ, NOT_EQ:
		return
	case:
		delete(literal)
	}
}

lookup_ident :: proc(ident: string) -> TokenType {
	if tok, ok := keywords[ident]; ok {
		return tok
	}
	return IDENT
}


new_lexer :: proc(input: string) -> ^Lexer {
	l := new(Lexer)
	l.input = input
	read_char(l)
	return l
}

delete_lexer :: proc(l: ^Lexer) {
	// for illegal in l.illegals {
	// 	delete(illegal)
	// }
	delete(l.illegals)
	free(l)
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
		if peek_char(l) == '=' {
			read_char(l)
			tok.type = EQ
			tok.literal = "=="
		} else {
			tok.type = ASSIGN
			tok.literal = "="
		}
	case '+':
		tok.type = PLUS
		tok.literal = "+"
	case '-':
		tok.type = MINUS
		tok.literal = "-"
	case '!':
		if peek_char(l) == '=' {
			read_char(l)
			tok.type = NOT_EQ
			tok.literal = "!="
		} else {
			tok.type = BANG
			tok.literal = "!"
		}
	case '/':
		tok.type = SLASH
		tok.literal = "/"
	case '*':
		tok.type = ASTERISK
		tok.literal = "*"
	case '<':
		tok.type = LT
		tok.literal = "<"
	case '>':
		tok.type = GT
		tok.literal = ">"
	case ';':
		tok.type = SEMICOLON
		tok.literal = ";"
	case ',':
		tok.type = COMMA
		tok.literal = ","
	case '(':
		tok.type = LPAREN
		tok.literal = "("
	case ')':
		tok.type = RPAREN
		tok.literal = ")"
	case '{':
		tok.type = LBRACE
		tok.literal = "{"
	case '}':
		tok.type = RBRACE
		tok.literal = "}"
	case 0:
		tok.type = EOF
		tok.literal = ""
	case:
		if is_letter(l.ch) {
			tok.literal = read_identifier(l)
			tok.type = lookup_ident(tok.literal)
			// append(&l.tokens, tok)
			return tok
		} else if is_digit(l.ch) {
			tok.literal = read_number(l)
			tok.type = INT
			// append(&l.tokens, tok)
			return tok
		} else {
			tok.literal = string_from_byte(l.ch)
			tok.type = ILLEGAL
			append(&l.illegals, tok.literal)
		}
	}

	read_char(l)

	// append(&l.tokens, tok)
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

peek_char :: proc(l: ^Lexer) -> byte {
	if l.read_position >= len(l.input) {
		return 0
	} else {
		return l.input[l.read_position]
	}
}
