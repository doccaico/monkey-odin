package repl

import "core:bufio"
import "core:io"
// import "core:fmt"

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

	evaluator.new_eval()
	defer evaluator.delete_eval()

	env := object.new_enviroment()
	defer object.delete_enviroment(env)

	program: ^ast.Program

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

		program = parser.parse_program(p)

		if len(parser.errors(p)) != 0 {
			print_parser_errors(stdout, parser.errors(p))
			continue
		}

		evaluated := evaluator.eval(program, env)
		if evaluated != nil {
			io.write_string(stdout, object.inspect(evaluated))
			io.write_rune(stdout, '\n')
		}

		ast.add_program(program)
	}

	ast.delete_programs(program)
}

print_parser_errors :: proc(stdout: io.Stream, errors: [dynamic]string) {
	io.write_string(stdout, "parser errors:\n")
	for msg in errors {
		io.write_rune(stdout, '\t')
		io.write_string(stdout, msg)
		io.write_rune(stdout, '\n')
	}
}
