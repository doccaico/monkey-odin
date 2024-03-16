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

keywords := map[string]TokenType {
	"fn"  = FUNCTION,
	"let" = LET,
	// "if" = IF,
	// "else" = ELSE,
	// "true" = TRUE,
	// "false" = FALSE,
	// "return" = RETURN,
}


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
	switch tok.type {
	case EOF, INT, FUNCTION, LET, IDENT:
		return
	case:
		delete(tok.literal)
	}
}

lookup_ident :: proc(ident: string) -> TokenType {
	if tok, ok := keywords[ident]; ok {
		return tok
	}
	return IDENT
}
