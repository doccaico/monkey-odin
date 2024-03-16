package monkey

// import "core:fmt"

ILLEGAL :: "ILLEGAL"
EOF :: "EOF"
// Identifiers and lierals
IDENT :: "IDENT"
INT :: "INT"
// Operators
ASSIGN :: "="
PLUS :: "+"
// MINUS :: "-"
// ASTERISK :: "*"
// SLASH :: "/"
// BANG :: "!"
// LT :: "<"
// GT :: ">"
// EQ :: "=="
// NOT_EQ :: "!="

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
// IF :: "IF"
// ELSE :: "ELSE"
// RETURN :: "RETURN"
// TRUE :: "TRUE"
// FALSE :: "FALSE"


TokenType :: distinct string

Token :: struct {
	type:    TokenType,
	literal: string,
}

new_token :: proc(token_type: TokenType, ch: byte) -> Token {
	buf := make([]u8, 1)
	buf[0] = ch
	// https://odin-lang.org/docs/overview/#from-u8-to-x
	return Token{type = token_type, literal = transmute(string)buf}
}

delete_token :: proc(tok: Token) {
	if tok.type == EOF {
		return
	}
	delete(tok.literal)
}

next_token :: proc(l: ^Lexer) -> Token {
	tok: Token

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
	}

	read_char(l)
	return tok
}
