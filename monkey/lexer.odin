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
