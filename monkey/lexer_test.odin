package monkey

import "core:fmt"
import "core:mem"
import "core:testing"

test_next_token1 :: proc(t: ^testing.T) {

	input := `=+(){},;`

	tests := []struct {
		expected_type:    TokenType,
		expected_literal: string,
	} {
		{ASSIGN, "="},
		{PLUS, "+"},
		{LPAREN, "("},
		{RPAREN, ")"},
		{LBRACE, "{"},
		{RBRACE, "}"},
		{COMMA, ","},
		{SEMICOLON, ";"},
		{EOF, ""},
	}

	l := new_lexer(input)
	defer delete_lexer(l)

	for tt, i in tests {
		tok := next_token(l)
		defer delete_token(tok)

		if tok.type != tt.expected_type {
			testing.errorf(
				t,
				"tests[%d] - tokentype wrong. expected=%q, got=%q",
				i,
				tt.expected_type,
				tok.type,
			)
		}

		if tok.literal != tt.expected_literal {
			testing.errorf(
				t,
				"tests[%d] - literal wrong. expected=%q, got=%q",
				i,
				tt.expected_literal,
				tok.literal,
			)
		}
	}
}

test_next_token2 :: proc(t: ^testing.T) {

	input := `let five = 5;
  let ten = 10;

  let add = fn(x, y) {
    x + y;
  };

  let result = add(five, ten);
  `

	tests := []struct {
		expected_type:    TokenType,
		expected_literal: string,
	} {
		{LET, "let"},
		{IDENT, "five"},
		{ASSIGN, "="},
		{INT, "5"},
		{SEMICOLON, ";"},
		{LET, "let"},
		{IDENT, "ten"},
		{ASSIGN, "="},
		{INT, "10"},
		{SEMICOLON, ";"},
		{LET, "let"},
		{IDENT, "add"},
		{ASSIGN, "="},
		{FUNCTION, "fn"},
		{LPAREN, "("},
		{IDENT, "x"},
		{COMMA, ","},
		{IDENT, "y"},
		{RPAREN, ")"},
		{LBRACE, "{"},
		{IDENT, "x"},
		{PLUS, "+"},
		{IDENT, "y"},
		{SEMICOLON, ";"},
		{RBRACE, "}"},
		{SEMICOLON, ";"},
		{LET, "let"},
		{IDENT, "result"},
		{ASSIGN, "="},
		{IDENT, "add"},
		{LPAREN, "("},
		{IDENT, "five"},
		{COMMA, ","},
		{IDENT, "ten"},
		{RPAREN, ")"},
		{SEMICOLON, ";"},
		{EOF, ""},
	}

	l := new_lexer(input)
	defer delete_lexer(l)

	for tt, i in tests {
		tok := next_token(l)
		defer delete_token(tok)

		if tok.type != tt.expected_type {
			testing.errorf(
				t,
				"tests[%d] - tokentype wrong. expected=%q, got=%q",
				i,
				tt.expected_type,
				tok.type,
			)
		}

		if tok.literal != tt.expected_literal {
			testing.errorf(
				t,
				"tests[%d] - literal wrong. expected=%q, got=%q",
				i,
				tt.expected_literal,
				tok.literal,
			)
		}
	}
}

run_test :: proc(t: ^testing.T, msg: string, func: proc(t: ^testing.T)) {
	fmt.println(msg)
	func(t)
}

@(test)
test_lexer_main :: proc(t: ^testing.T) {

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	run_test(t, "[RUN] test_next_token1", test_next_token1)
	run_test(t, "[RUN] test_next_token2", test_next_token2)
	// run_test(t, "[RUN] test_next_token", test_next_token)

}
