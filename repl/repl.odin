package repl

import "core:bufio"
import "core:fmt"
import "core:io"

import "../lexer"
// import "../parser"

PROMPT :: ">> "

start :: proc(stdin: io.Stream) {

	r: bufio.Reader

	bufio.reader_init(&r, io.to_reader(stdin))
	defer bufio.reader_destroy(&r)

	for {
		fmt.print(PROMPT)
		line, err := bufio.reader_read_string(&r, '\n')
		defer delete(line)

		// Ctrl + z (on Windows)
		if err != nil {
			break
		}

		l := lexer.new_lexer(line)
		defer lexer.delete_lexer(l)

		for {
			tok := lexer.next_token(l)

			if tok.type == lexer.EOF {
				break
			}

			fmt.printf("%+v\n", tok)
		}
	}

}
