package monkey

import "core:fmt"
import "core:mem"
import "core:testing"

test_let_stmts :: proc(t: ^testing.T) {
	input := `
  let x = 5;
  let y = 10;
  let foobar = 838383;
  `

	l := new_lexer(input)
	defer delete_lexer(l)
	p := new_parser(l)
	defer delete_parser(p)

	program := parse_program(p)

	if program == nil {
		fmt.panicf("ParseProgram() returned nil")
	}
	if len(program.statements) != 3 {
		fmt.panicf(
			"program.Statements does not contain 3 statements. got=%d",
			len(program.statements),
		)
	}

	tests := []struct {
		expected_ident: string,
	}{{"x"}, {"y"}, {"foobar"}}

	for tt, i in tests {
		stmt := program.statements[i]
		if !test_let_stmt(t, stmt, tt.expected_ident) {
			return
		}
	}

}

test_let_stmt :: proc(t: ^testing.T, s: ^Stmt, name: string) -> bool {

	if token_literal(s.expr_base) != "let" {
		// testing.errorf(t, "s.TokenLiteral not 'let'. got=%q", s.TokenLiteral())
		testing.errorf(t, "s.TokenLiteral not 'let'. got=%q", "punk")
		return false
	}

	// letStmt, ok := s.(*ast.LetStatement)
	// if !ok {
	//   t.Errorf("s not *ast.LetStatement. got=%T", s)
	//   return false
	// }
	//
	// if letStmt.Name.Value != name {
	//   t.Errorf("letStmt.Name.Value not '%s'. got=%s", name, letStmt.Name.Value)
	//   return false
	// }
	//
	// if letStmt.Name.TokenLiteral() != name {
	//   t.Errorf("s.Name not '%s'. got=%s", name, letStmt.Name)
	//   return false
	// }

	return true
}

@(test)
test_parser_main :: proc(t: ^testing.T) {

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

	run_test(t, "[RUN] test_let_stmts", test_let_stmts)
}
