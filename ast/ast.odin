package ast

import "core:bytes"
import "core:fmt"
import "core:intrinsics"
import "core:mem"
import "core:strings"

import "../lexer"

Any_Node :: union {
	^Program,

	// Stmts
	^Let_Stmt,
	^Return_Stmt,
	^Expr_Stmt,
	^Block_Stmt,

	// Exprs
	^Ident,
	^Int_Literal,
	^Prefix_Expr,
	^Infix_Expr,
	^Bool_Literal,
	^If_Expr,
	// ^String_Literal,
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

Block_Stmt :: struct {
	using node: Stmt,
	token:      lexer.Token,
	statements: [dynamic]^Stmt,
}

// Exprs

Ident :: struct {
	using node: Expr,
	token:      lexer.Token,
	value:      string,
}

Int_Literal :: struct {
	using node: Expr,
	token:      lexer.Token,
	value:      i64,
}

Prefix_Expr :: struct {
	using node: Expr,
	token:      lexer.Token,
	operator:   string,
	right:      ^Expr,
}

Infix_Expr :: struct {
	using node: Expr,
	token:      lexer.Token,
	left:       ^Expr,
	operator:   string,
	right:      ^Expr,
}

Bool_Literal :: struct {
	using node: Expr,
	token:      lexer.Token,
	value:      bool,
}

If_Expr :: struct {
	using node:  Expr,
	token:       lexer.Token,
	condition:   ^Expr,
	consequence: ^Block_Stmt,
	alternative: ^Block_Stmt,
}

new_node :: proc($T: typeid) -> ^T where intrinsics.type_has_field(T, "derived") {
	node := new(T)
	node.derived = node
	// fmt.println(node.derived)
	// fmt.printf("%p\n", node)
	// fmt.println()

	return node
}

delete_program :: proc(program: ^Program) {
	// fmt.println("In [Fn] delete_program")
	for stmt in program.statements {
		#partial switch t in stmt.expr_base.derived {
		// case ^ast.Program:
		// fmt.println("In Program")
		case ^Expr_Stmt:
			free_expr_stmt(t.expr)
			free(t.expr)
		case ^Let_Stmt:
			// fmt.println("In Let_Stmt")
			free(t.name)
			free(t.value)
		case ^Return_Stmt:
			// fmt.printf("In Return_Stmt")
			free(t.return_value)
		// case ^Ident:
		// 	fmt.printf("In Ident %s\n", t.value)
		// case ^Prefix_Expr:
		// 	fmt.println("In Prefix_Expr")
		// 	free(t.right)
		// case ^Int_Literal: return int_literal_string(v)
		// case ^Block_Stmt:
		// 	fmt.printf("In Block_Stmt")
		// return block_stmt_string(v)
		// return ident_token_literal(v)
		// case ^String_Literal: return string_literal_string(v)
		// return bool_literal_string(v)
		// case ^Bool_Literal:
		// 	fmt.printf("bool literal\n")
		// case ^Infix_Expr:
		// 	fmt.println("Infix_Expr")
		// case ^If_Expr:
		// 	fmt.println("If_Expr")
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

free_expr_stmt :: proc(expr: ^Expr) {
	// fmt.println(expr)
	// fmt.println("In [Fn] free_expr_stmt")
	#partial switch t in expr.expr_base.derived {
	case ^Prefix_Expr:
		free_expr_stmt(t.right)
		free(t.right)
	case ^Infix_Expr:
		free_expr_stmt(t.left)
		free(t.left)
		free_expr_stmt(t.right)
		free(t.right)
	case ^If_Expr:
		free_expr_stmt(t.condition)
		free(t.condition)

		for stmt in t.consequence.statements {
			free(stmt.derived.(^Expr_Stmt).expr)
			free(stmt)
		}
		delete(t.consequence.statements)
		free(t.consequence)

		if t.alternative != nil {
			for stmt in t.alternative.statements {
				free(stmt)
			}
			delete(t.alternative.statements)
			free(t.alternative)
		}
	// case ^Expr_Stmt:
	// 	fmt.printf("Expr_Stmt\n")
	// case ^Bool_Literal:
	// 	fmt.printf("bool literal\n")
	// case ^Ident:
	// 	fmt.printf("In Ident %s\n", t.value)
	// 	a := expr.expr_base.derived.(^Ident)
	// 	free(a)
	// free(t.value)
	// case ^Block_Stmt:
	// 	fmt.println("In Block_Stmt")
	// case:
	// 	fmt.println(t)
	}
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
	case ^Ident:
		return ident_token_literal(v)
	case ^Int_Literal:
		return int_literal_token_literal(v)
	case ^Prefix_Expr:
		return prefix_expr_token_literal(v)
	case ^Infix_Expr:
		return infix_expr_token_literal(v)
	case ^Bool_Literal:
		return bool_literal_token_literal(v)
	case ^If_Expr:
		return if_expr_token_literal(v)
	case ^Block_Stmt:
		return block_stmt_token_literal(v)
	// case ^String_Literal: return string_literal_string(v)
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

int_literal_token_literal :: proc(e: ^Int_Literal) -> string {
	return e.token.literal
}

prefix_expr_token_literal :: proc(e: ^Prefix_Expr) -> string {
	return e.token.literal
}

infix_expr_token_literal :: proc(e: ^Infix_Expr) -> string {
	return e.token.literal
}

bool_literal_token_literal :: proc(e: ^Bool_Literal) -> string {
	return e.token.literal
}

if_expr_token_literal :: proc(e: ^If_Expr) -> string {
	return e.token.literal
}

block_stmt_token_literal :: proc(e: ^Block_Stmt) -> string {
	return e.token.literal
}

// to_string

to_string :: proc(node: Node) -> bytes.Buffer {
	switch v in node.derived {
	case ^Program:
		return program_to_string(v)
	case ^Let_Stmt:
		return let_stmt_to_string(v)
	case ^Return_Stmt:
		return return_stmt_to_string(v)
	case ^Expr_Stmt:
		return expr_stmt_to_string(v)
	case ^Ident:
		return ident_to_string(v)
	case ^Int_Literal:
		return int_literal_to_string(v)
	case ^Prefix_Expr:
		return prefix_expr_to_string(v)
	case ^Infix_Expr:
		return infix_expr_to_string(v)
	case ^Bool_Literal:
		return bool_literal_to_string(v)
	case ^If_Expr:
		return if_expr_to_string(v)
	case ^Block_Stmt:
		return block_stmt_to_string(v)
	// case ^String_Literal:
	// 	return string_literal_string(v)
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

program_to_string :: proc(p: ^Program) -> bytes.Buffer {
	out: bytes.Buffer

	for stmt in p.statements {
		buf := to_string(stmt)
		defer bytes.buffer_destroy(&buf)
		bytes.buffer_write(&out, bytes.buffer_to_bytes(&buf))
	}

	return out
}

let_stmt_to_string :: proc(s: ^Let_Stmt) -> bytes.Buffer {
	out: bytes.Buffer

	bytes.buffer_write(&out, transmute([]u8)token_literal(s))
	bytes.buffer_write(&out, transmute([]u8)string(" "))

	name_buf := to_string(s.name)
	defer bytes.buffer_destroy(&name_buf)
	bytes.buffer_write(&out, bytes.buffer_to_bytes(&name_buf))

	bytes.buffer_write(&out, transmute([]u8)string(" = "))

	if s.value != nil {
		value_buf := to_string(s.value)
		defer bytes.buffer_destroy(&value_buf)
		bytes.buffer_write(&out, bytes.buffer_to_bytes(&value_buf))
	}

	bytes.buffer_write(&out, transmute([]u8)string(";"))

	return out
}

return_stmt_to_string :: proc(s: ^Return_Stmt) -> bytes.Buffer {
	out: bytes.Buffer

	bytes.buffer_write(&out, transmute([]u8)token_literal(s))
	bytes.buffer_write(&out, transmute([]u8)string(" "))

	if s.return_value != nil {
		buf := to_string(s.return_value)
		defer bytes.buffer_destroy(&buf)
		bytes.buffer_write(&out, bytes.buffer_to_bytes(&buf))
	}

	bytes.buffer_write(&out, transmute([]u8)string(";"))

	return out
}

expr_stmt_to_string :: proc(s: ^Expr_Stmt) -> bytes.Buffer {
	out: bytes.Buffer

	if s.expr != nil {
		return to_string(s.expr)
	}

	return out
}

ident_to_string :: proc(e: ^Ident) -> bytes.Buffer {
	out: bytes.Buffer

	bytes.buffer_write_string(&out, e.value)

	return out
}

int_literal_to_string :: proc(e: ^Int_Literal) -> bytes.Buffer {
	out: bytes.Buffer

	bytes.buffer_write_string(&out, e.token.literal)

	return out
}

prefix_expr_to_string :: proc(e: ^Prefix_Expr) -> bytes.Buffer {
	out: bytes.Buffer

	bytes.buffer_write(&out, transmute([]u8)string("("))
	bytes.buffer_write(&out, transmute([]u8)e.operator)

	buf := to_string(e.right)
	defer bytes.buffer_destroy(&buf)
	bytes.buffer_write(&out, bytes.buffer_to_bytes(&buf))

	bytes.buffer_write(&out, transmute([]u8)string(")"))

	return out
}

infix_expr_to_string :: proc(e: ^Infix_Expr) -> bytes.Buffer {
	out: bytes.Buffer

	bytes.buffer_write(&out, transmute([]u8)string("("))

	left_buf := to_string(e.left)
	defer bytes.buffer_destroy(&left_buf)
	bytes.buffer_write(&out, bytes.buffer_to_bytes(&left_buf))

	bytes.buffer_write(&out, transmute([]u8)string(" "))
	bytes.buffer_write(&out, transmute([]u8)e.operator)
	bytes.buffer_write(&out, transmute([]u8)string(" "))

	right_buf := to_string(e.right)
	defer bytes.buffer_destroy(&right_buf)
	bytes.buffer_write(&out, bytes.buffer_to_bytes(&right_buf))

	bytes.buffer_write(&out, transmute([]u8)string(")"))

	return out
}

bool_literal_to_string :: proc(e: ^Bool_Literal) -> bytes.Buffer {
	out: bytes.Buffer

	bytes.buffer_write_string(&out, e.token.literal)

	return out
}

if_expr_to_string :: proc(e: ^If_Expr) -> bytes.Buffer {
	out: bytes.Buffer

	bytes.buffer_write_string(&out, "if")

	condition_buf := to_string(e.condition)
	defer bytes.buffer_destroy(&condition_buf)
	bytes.buffer_write(&out, bytes.buffer_to_bytes(&condition_buf))

	bytes.buffer_write_string(&out, " ")

	consequence_buf := to_string(e.consequence)
	defer bytes.buffer_destroy(&consequence_buf)
	bytes.buffer_write(&out, bytes.buffer_to_bytes(&consequence_buf))

	if e.alternative != nil {
		bytes.buffer_write_string(&out, "else ")

		alternative_buf := to_string(e.alternative)
		defer bytes.buffer_destroy(&alternative_buf)
		bytes.buffer_write(&out, bytes.buffer_to_bytes(&alternative_buf))
	}

	return out
}

block_stmt_to_string :: proc(s: ^Block_Stmt) -> bytes.Buffer {
	out: bytes.Buffer

	for stmt in s.statements {
		buf := to_string(stmt)
		defer bytes.buffer_destroy(&buf)
		bytes.buffer_write(&out, bytes.buffer_to_bytes(&buf))
	}

	return out
}
