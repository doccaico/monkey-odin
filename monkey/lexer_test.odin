package monkey

import "core:fmt"
import "core:mem"
import "core:testing"

@(test)
test_next_token :: proc(t: ^testing.T) {

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
