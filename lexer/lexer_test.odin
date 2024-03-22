package lexer

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

		if tok.type != tt.expected_type {
			fmt.panicf(
				"tests[%d] - tokentype wrong. expected=%q, got=%q",
				i,
				tt.expected_type,
				tok.type,
			)
		}

		if tok.literal != tt.expected_literal {
			fmt.panicf(
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

		if tok.type != tt.expected_type {
			fmt.panicf(
				"tests[%d] - tokentype wrong. expected=%q, got=%q",
				i,
				tt.expected_type,
				tok.type,
			)
		}

		if tok.literal != tt.expected_literal {
			fmt.panicf(
				"tests[%d] - literal wrong. expected=%q, got=%q",
				i,
				tt.expected_literal,
				tok.literal,
			)
		}
	}
}

test_next_token3 :: proc(t: ^testing.T) {

	input := `
  !-/*5;
  5 < 10 > 5;
  `

	tests := []struct {
		expected_type:    TokenType,
		expected_literal: string,
	} {
		{BANG, "!"},
		{MINUS, "-"},
		{SLASH, "/"},
		{ASTERISK, "*"},
		{INT, "5"},
		{SEMICOLON, ";"},
		{INT, "5"},
		{LT, "<"},
		{INT, "10"},
		{GT, ">"},
		{INT, "5"},
		{SEMICOLON, ";"},
		{EOF, ""},
	}

	l := new_lexer(input)
	defer delete_lexer(l)

	for tt, i in tests {
		tok := next_token(l)

		if tok.type != tt.expected_type {
			fmt.panicf(
				"tests[%d] - tokentype wrong. expected=%q, got=%q",
				i,
				tt.expected_type,
				tok.type,
			)
		}

		if tok.literal != tt.expected_literal {
			fmt.panicf(
				"tests[%d] - literal wrong. expected=%q, got=%q",
				i,
				tt.expected_literal,
				tok.literal,
			)
		}
	}
}

test_next_token4 :: proc(t: ^testing.T) {

	input := `
  if (5 < 10) {
    return true;
  } else {
    return false;
  }`

	tests := []struct {
		expected_type:    TokenType,
		expected_literal: string,
	} {
		{IF, "if"},
		{LPAREN, "("},
		{INT, "5"},
		{LT, "<"},
		{INT, "10"},
		{RPAREN, ")"},
		{LBRACE, "{"},
		{RETURN, "return"},
		{TRUE, "true"},
		{SEMICOLON, ";"},
		{RBRACE, "}"},
		{ELSE, "else"},
		{LBRACE, "{"},
		{RETURN, "return"},
		{FALSE, "false"},
		{SEMICOLON, ";"},
		{RBRACE, "}"},
		{EOF, ""},
	}

	l := new_lexer(input)
	defer delete_lexer(l)

	for tt, i in tests {
		tok := next_token(l)

		if tok.type != tt.expected_type {
			fmt.panicf(
				"tests[%d] - tokentype wrong. expected=%q, got=%q",
				i,
				tt.expected_type,
				tok.type,
			)
		}

		if tok.literal != tt.expected_literal {
			fmt.panicf(
				"tests[%d] - literal wrong. expected=%q, got=%q",
				i,
				tt.expected_literal,
				tok.literal,
			)
		}
	}
}

test_next_token5 :: proc(t: ^testing.T) {

	input := `
  10 == 10;
  10 != 9;
  `

	tests := []struct {
		expected_type:    TokenType,
		expected_literal: string,
	} {
		{INT, "10"},
		{EQ, "=="},
		{INT, "10"},
		{SEMICOLON, ";"},
		{INT, "10"},
		{NOT_EQ, "!="},
		{INT, "9"},
		{SEMICOLON, ";"},
		{EOF, ""},
	}

	l := new_lexer(input)
	defer delete_lexer(l)

	for tt, i in tests {
		tok := next_token(l)

		if tok.type != tt.expected_type {
			fmt.panicf(
				"tests[%d] - tokentype wrong. expected=%q, got=%q",
				i,
				tt.expected_type,
				tok.type,
			)
		}

		if tok.literal != tt.expected_literal {
			fmt.panicf(
				"tests[%d] - literal wrong. expected=%q, got=%q",
				i,
				tt.expected_literal,
				tok.literal,
			)
		}
	}
}

test_next_token_string :: proc(t: ^testing.T) {
	input := `
  "foobar"
  "foo bar"
  `

	tests := []struct {
		expected_type:    TokenType,
		expected_literal: string,
	}{{STRING, "foobar"}, {STRING, "foo bar"}, {EOF, ""}}

	l := new_lexer(input)
	defer delete_lexer(l)

	for tt, i in tests {
		tok := next_token(l)

		if tok.type != tt.expected_type {
			fmt.panicf(
				"tests[%d] - tokentype wrong. expected=%q, got=%q",
				i,
				tt.expected_type,
				tok.type,
			)
		}

		if tok.literal != tt.expected_literal {
			fmt.panicf(
				"tests[%d] - literal wrong. expected=%q, got=%q",
				i,
				tt.expected_literal,
				tok.literal,
			)
		}
	}
}

test_next_token_array :: proc(t: ^testing.T) {
	input := `
    [1, 2];
    `
	tests := []struct {
		expected_type:    TokenType,
		expected_literal: string,
	} {
		{LBRACKET, "["},
		{INT, "1"},
		{COMMA, ","},
		{INT, "2"},
		{RBRACKET, "]"},
		{SEMICOLON, ";"},
		{EOF, ""},
	}

	l := new_lexer(input)
	defer delete_lexer(l)

	for tt, i in tests {
		tok := next_token(l)

		if tok.type != tt.expected_type {
			fmt.panicf(
				"tests[%d] - tokentype wrong. expected=%q, got=%q",
				i,
				tt.expected_type,
				tok.type,
			)
		}

		if tok.literal != tt.expected_literal {
			fmt.panicf(
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

	// run_test(t, "[RUN] test_next_token1", test_next_token1)
	// run_test(t, "[RUN] test_next_token2", test_next_token2)
	// run_test(t, "[RUN] test_next_token3", test_next_token3)
	// run_test(t, "[RUN] test_next_token4", test_next_token4)
	// run_test(t, "[RUN] test_next_token5", test_next_token5)
	// run_test(t, "[RUN] test_next_token_string", test_next_token_string)
	run_test(t, "[RUN] test_next_token_array", test_next_token_array)
}
