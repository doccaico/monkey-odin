package ast

import "core:bytes"
import "core:fmt"
import "core:intrinsics"
import "core:mem"

import "../lexer"

Any_Node :: union {
	^Program,

	// Stmts
	^Expr_Stmt,
	^Let_Stmt,
	^Return_Stmt,
	// ^Block_Stmt,

	// Exprs
	^Ident,
	// ^Int_Literal,
	// ^String_Literal,
	// ^Bool_Literal,
	// ^Prefix_Expr,
	// ^Infix_Expr,
	// ^If_Expr,
	// ^Function_Literal,
	// ^Call_Expr,
	// ^Array_Literal,
	// ^Index_Expr,
	// ^Hash_Expr,
}

Node :: struct {
	derived: Any_Node,
}

Expr :: struct {
	using expr_base: Node,
	// derived_expr: Any_Node,
}

Stmt :: struct {
	using expr_base: Node,
	// derived_stmt: Any_Node,
}

// Program

Program :: struct {
	using node: Node,
	statements: [dynamic]^Stmt,
}

// Stmts

Let_Stmt :: struct {
	using node: Stmt,
	token:      lexer.Token,
	name:       ^Ident,
	value:      ^Expr,
}

Return_Stmt :: struct {
	using node:   Stmt,
	token:        lexer.Token,
	return_value: ^Expr,
}

Expr_Stmt :: struct {
	using node: Stmt,
	token:      lexer.Token,
	expr:       ^Expr,
}

// Exprs

Ident :: struct {
	using node: Expr,
	token:      lexer.Token,
	value:      string,
}

new_node :: proc($T: typeid) -> ^T where intrinsics.type_has_field(T, "derived") {
	node := new(T)
	node.derived = node

	return node
}

delete_program :: proc(program: ^Program) {

	for stmt in program.statements {
		// switch v in program.statements[0].node.derived {
		#partial switch t in stmt.expr_base.derived {
		// case ^ast.Program:
		// 	fmt.printf("case Program\n")
		// 	return program_token_literal(v)
		// case ^Expr_Stmt: return expr_stmt_string(v)
		case ^Let_Stmt:
			// fmt.println("In Let_Stmt")
			free(t.name)
			free(t.value)
		case ^Return_Stmt:
			// fmt.printf("In Return_Stmt")
			free(t.return_value)
		// case ^Block_Stmt: return block_stmt_string(v)
		// case ^Ident:
		// 	return ident_token_literal(v)
		// case ^Int_Literal: return int_literal_string(v)
		// case ^String_Literal: return string_literal_string(v)
		// case ^Bool_Literal: return bool_literal_string(v)
		// case ^Prefix_Expr: return prefix_expr_string(v)
		// case ^Infix_Expr: return infix_expr_string(v)
		// case ^If_Expr: return if_expr_string(v)
		// case ^Function_Literal: return function_expr_string(v)
		// case ^Call_Expr: return call_expr_string(v)
		// case ^Array_Literal: return array_expr_string(v)
		// case ^Index_Expr: return index_expr_string(v)
		// case ^Hash_Expr: return hash_expr_string(v)
		case:
			panic("delete_program: unknown node type")
		}
		free(stmt)
	}
	delete(program.statements)
	free(program)
}


// token_literal

token_literal :: proc(node: Node) -> string {
	switch v in node.derived {
	case ^Program:
		return program_token_literal(v)
	case ^Let_Stmt:
		return let_stmt_token_literal(v)
	case ^Return_Stmt:
		return return_stmt_token_literal(v)
	case ^Expr_Stmt:
		return expr_stmt_token_literal(v)
	// case ^Block_Stmt: return block_stmt_string(v)
	case ^Ident:
		return ident_token_literal(v)
	// case ^Int_Literal: return int_literal_string(v)
	// case ^String_Literal: return string_literal_string(v)
	// case ^Bool_Literal: return bool_literal_string(v)
	// case ^Prefix_Expr: return prefix_expr_string(v)
	// case ^Infix_Expr: return infix_expr_string(v)
	// case ^If_Expr: return if_expr_string(v)
	// case ^Function_Literal: return function_expr_string(v)
	// case ^Call_Expr: return call_expr_string(v)
	// case ^Array_Literal: return array_expr_string(v)
	// case ^Index_Expr: return index_expr_string(v)
	// case ^Hash_Expr: return hash_expr_string(v)
	case:
		panic("token_literal: unknown node type")
	}
}

program_token_literal :: proc(p: ^Program) -> string {
	if len(p.statements) > 0 {
		return token_literal(p.statements[0])
	} else {
		return ""
	}
}

let_stmt_token_literal :: proc(s: ^Let_Stmt) -> string {
	return s.token.literal
}

return_stmt_token_literal :: proc(s: ^Return_Stmt) -> string {
	return s.token.literal
}

expr_stmt_token_literal :: proc(s: ^Expr_Stmt) -> string {
	return s.token.literal
}

ident_token_literal :: proc(e: ^Ident) -> string {
	return e.token.literal
}

// to_string

to_string :: proc(node: Node) -> string {
	switch v in node.derived {
	case ^Program:
		return program_to_string(v)
	case ^Let_Stmt:
		return let_stmt_to_string(v)
	case ^Return_Stmt:
		return return_stmt_to_string(v)
	case ^Expr_Stmt:
		return expr_stmt_to_string(v)
	// case ^Block_Stmt:
	// 	return block_stmt_string(v)
	case ^Ident:
		return ident_to_string(v)
	// case ^Int_Literal:
	// 	return int_literal_string(v)
	// case ^String_Literal:
	// 	return string_literal_string(v)
	// case ^Bool_Literal:
	// 	return bool_literal_string(v)
	// case ^Prefix_Expr:
	// 	return prefix_expr_string(v)
	// case ^Infix_Expr:
	// 	return infix_expr_string(v)
	// case ^If_Expr:
	// 	return if_expr_string(v)
	// case ^Function_Literal:
	// 	return function_expr_string(v)
	// case ^Call_Expr:
	// 	return call_expr_string(v)
	// case ^Array_Literal:
	// 	return array_expr_string(v)
	// case ^Index_Expr:
	// 	return index_expr_string(v)
	// case ^Hash_Expr:
	// 	return hash_expr_string(v)
	case:
		panic("to_string: unknown node type")
	}
}

program_to_string :: proc(p: ^Program) -> string {
	out: bytes.Buffer

	for stmt in p.statements {
		s := to_string(stmt)
		bytes.buffer_write(&out, transmute([]u8)s)
		delete(s)
	}

	return bytes.buffer_to_string(&out)
}

let_stmt_to_string :: proc(s: ^Let_Stmt) -> string {
	out: bytes.Buffer

	bytes.buffer_write(&out, transmute([]u8)token_literal(s))
	bytes.buffer_write(&out, transmute([]u8)string(" "))
	bytes.buffer_write(&out, transmute([]u8)to_string(s.name))
	bytes.buffer_write(&out, transmute([]u8)string(" = "))

	if s.value != nil {
		bytes.buffer_write(&out, transmute([]u8)to_string(s.value))
	}

	bytes.buffer_write(&out, transmute([]u8)string(";"))

	return bytes.buffer_to_string(&out)
}

return_stmt_to_string :: proc(s: ^Return_Stmt) -> string {
	out: bytes.Buffer

	bytes.buffer_write(&out, transmute([]u8)token_literal(s))
	bytes.buffer_write(&out, transmute([]u8)string(" "))

	if s.return_value != nil {
		bytes.buffer_write(&out, transmute([]u8)to_string(s.return_value))
	}

	bytes.buffer_write(&out, transmute([]u8)string(";"))

	return bytes.buffer_to_string(&out)
}

expr_stmt_to_string :: proc(s: ^Expr_Stmt) -> string {
	if s.expr != nil {
		return to_string(s.expr)
	}
	return ""
}

ident_to_string :: proc(e: ^Ident) -> string {
	// out: bytes.Buffer
	//
	// bytes.buffer_write(&out, transmute([]u8)e.value)
	//
	// return bytes.buffer_to_string(&out)
	return e.value
}
