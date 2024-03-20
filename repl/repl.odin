package repl

import "core:bufio"
import "core:io"
// import "core:bytes"

import "../ast"
import "../evaluator"
import "../lexer"
import "../object"
import "../parser"

PROMPT :: ">> "

start :: proc(stdin: io.Stream, stdout: io.Stream) {

	scanner: bufio.Scanner
	bufio.scanner_init(&scanner, stdin)
	defer bufio.scanner_destroy(&scanner)

	for {
		io.write_string(stdout, PROMPT)

		scanned := bufio.scanner_scan(&scanner)

		// Ctrl + z (on Windows)
		if !scanned {
			break
		}

		line := bufio.scanner_text(&scanner)

		l := lexer.new_lexer(line)
		defer lexer.delete_lexer(l)

		p := parser.new_parser(l)
		defer parser.delete_parser(p)

		program := parser.parse_program(p)
		defer ast.delete_program(program)

		if len(parser.errors(p)) != 0 {
			print_parser_errors(stdout, parser.errors(p))
			continue
		}

		// buf := ast.to_string(program)
		// defer bytes.buffer_destroy(&buf)
		// s := bytes.buffer_to_string(&buf)
		//
		// io.write_string(stdout, s)
		// io.write_rune(stdout, '\n')

		evaluated := evaluator.eval(program)
		defer object.delete_object(evaluated)
		if evaluated != nil {
			io.write_string(stdout, object.inspect(evaluated))
			io.write_rune(stdout, '\n')
		}

	}
}

print_parser_errors :: proc(stdout: io.Stream, errors: [dynamic]string) {
	io.write_string(stdout, "parser errors:\n")
	for msg in errors {
		io.write_rune(stdout, '\t')
		io.write_string(stdout, msg)
		io.write_rune(stdout, '\n')
	}
}
