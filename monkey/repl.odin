package monkey

import "core:bufio"
import "core:fmt"
import "core:io"

PROMPT :: ">> "

start :: proc(stdin: io.Stream) {

	r: bufio.Reader

	bufio.reader_init(&r, io.to_reader(stdin))
	defer bufio.reader_destroy(&r)

	for {
		fmt.print(PROMPT)
		line, err := bufio.reader_read_string(&r, '\n')
		defer delete(line)

		// Ctrl+ z
		if err != nil {
			break
		}

		l := new_lexer(line)
		defer delete_lexer(l)

		for {
			tok := next_token(l)
			defer delete_token(tok)

			if tok.type == EOF {
				break
			}

			fmt.printf("%+v\n", tok)
		}
	}

}
