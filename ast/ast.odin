package ast

import "core:bytes"
import "core:fmt"
import "core:intrinsics"
import "core:mem"
import "core:strings"

import "../lexer"

program_list: [dynamic]^Program

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
	^Function_Literal,
	^Call_Expr,
	^String_Literal,
	^Array_Literal,
	^Index_Expr,
	^Hash_Literal,
}

Node :: struct {
	derived: Any_Node,
}

Expr :: struct {
	using expr_base: Node,
}

Stmt :: struct {
	using expr_base: Node,
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

Function_Literal :: struct {
	using node: Expr,
	token:      lexer.Token,
	parameters: [dynamic]^Ident,
	body:       ^Block_Stmt,
}

Call_Expr :: struct {
	using node: Expr,
	token:      lexer.Token,
	function:   ^Expr,
	arguments:  [dynamic]^Expr,
}

String_Literal :: struct {
	using node: Expr,
	token:      lexer.Token,
	value:      string,
}

Array_Literal :: struct {
	using node: Expr,
	token:      lexer.Token,
	elements:   [dynamic]^Expr,
}

Index_Expr :: struct {
	using node: Expr,
	token:      lexer.Token,
	left:       ^Expr,
	index:      ^Expr,
}

Hash_Literal :: struct {
	using node: Expr,
	token:      lexer.Token,
	pairs:      map[^Expr]^Expr,
}

new_node :: proc($T: typeid) -> ^T where intrinsics.type_has_field(T, "derived") {
	node := new(T)
	node.derived = node

	// fmt.printf("1. Node: %v\n", node)
	// fmt.printf("2. Pointer: %p\n", node)
	// fmt.println()

	return node
}

delete_program :: proc(program: ^Program) {
	for stmt in program.statements {
		#partial switch t in stmt.derived {
		case ^Expr_Stmt:
			free_expr_stmt(t.expr)
		case ^Let_Stmt:
			free(t.name)
			free_expr_stmt(t.value)
		case ^Return_Stmt:
			free_expr_stmt(t.return_value)
		case:
			panic("delete_program: unknown node type")
		}
		free(stmt)
	}
	delete(program.statements)
	free(program)
}

free_expr_stmt :: proc(expr: ^Expr) {
	#partial switch t in expr.expr_base.derived {
	case ^Prefix_Expr:
		free_expr_stmt(t.right)
		free(t)
	case ^Infix_Expr:
		free_expr_stmt(t.left)
		free_expr_stmt(t.right)
		free(t)
	case ^If_Expr:
		free_expr_stmt(t.condition)

		for stmt in t.consequence.statements {
			#partial switch t in stmt.derived {
			case ^Expr_Stmt:
				free_expr_stmt(t.expr)
			case ^Return_Stmt:
				free_expr_stmt(t.return_value)
			}
			free(stmt)
		}
		delete(t.consequence.statements)
		free(t.consequence)

		if t.alternative != nil {
			for stmt in t.alternative.statements {
				#partial switch t in stmt.derived {
				case ^Expr_Stmt:
					free_expr_stmt(t.expr)
				case ^Return_Stmt:
					free_expr_stmt(t.return_value)
				}
				free(stmt)
			}
			delete(t.alternative.statements)
			free(t.alternative)
		}
		free(t)
	case ^Function_Literal:
		for ident in t.parameters {
			free(ident)
		}
		delete(t.parameters)

		for stmt in t.body.statements {
			#partial switch t in stmt.derived {
			case ^Expr_Stmt:
				free_expr_stmt(t.expr)
			case ^Let_Stmt:
				free(t.name)
				free_expr_stmt(t.value)
			case ^Return_Stmt:
				free_expr_stmt(t.return_value)
			}
			free(stmt)
		}
		delete(t.body.statements)
		free(t.body)
		free(t)
	case ^Bool_Literal:
		free(t)
	case ^Ident:
		free(t)
	case ^Int_Literal:
		free(t)
	case ^Call_Expr:
		free_expr_stmt(t.function)
		for expr in t.arguments {
			free_expr_stmt(expr)
		}
		delete(t.arguments)
		free(t)
	case ^String_Literal:
		free(t)
	case ^Array_Literal:
		for expr in t.elements {
			free_expr_stmt(expr)
		}
		delete(t.elements)
		free(t)
	case ^Index_Expr:
		free_expr_stmt(t.left)
		free_expr_stmt(t.index)
		free(t)
	case ^Hash_Literal:
		for key, value in t.pairs {
			free_expr_stmt(key)
			free_expr_stmt(value)
		}
		delete(t.pairs)
		free(t)
	case:
		// fmt.println(t)
		panic("free_expr_stmt: unknown expr type")
	}
}

add_program :: proc(program: ^Program) {
	append(&program_list, program)
}

delete_programs :: proc(program: ^Program) {
	for p in program_list {
		delete_program(p)
	}
	delete(program_list)
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
	case ^Function_Literal:
		return function_literal_token_literal(v)
	case ^Call_Expr:
		return call_expr_token_literal(v)
	case ^String_Literal:
		return string_literal_token_literal(v)
	case ^Array_Literal:
		return array_literal_token_literal(v)
	case ^Index_Expr:
		return index_expr_token_literal(v)
	case ^Hash_Literal:
		return hash_literal_token_literal(v)
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

function_literal_token_literal :: proc(e: ^Function_Literal) -> string {
	return e.token.literal
}

call_expr_token_literal :: proc(e: ^Call_Expr) -> string {
	return e.token.literal
}

string_literal_token_literal :: proc(e: ^String_Literal) -> string {
	return e.token.literal
}

array_literal_token_literal :: proc(e: ^Array_Literal) -> string {
	return e.token.literal
}

index_expr_token_literal :: proc(e: ^Index_Expr) -> string {
	return e.token.literal
}

hash_literal_token_literal :: proc(e: ^Hash_Literal) -> string {
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
	case ^Function_Literal:
		return function_literal_to_string(v)
	case ^Call_Expr:
		return call_expr_to_string(v)
	case ^String_Literal:
		return string_literal_to_string(v)
	case ^Array_Literal:
		return array_literal_to_string(v)
	case ^Index_Expr:
		return index_expr_to_string(v)
	case ^Hash_Literal:
		return hash_literal_to_string(v)
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

function_literal_to_string :: proc(e: ^Function_Literal) -> bytes.Buffer {
	out: bytes.Buffer

	params: [dynamic]string
	defer delete(params)

	for p in e.parameters {

		buf := to_string(p)
		defer bytes.buffer_destroy(&buf)
		append(&params, bytes.buffer_to_string(&buf))
	}

	bytes.buffer_write_string(&out, token_literal(e))
	bytes.buffer_write_string(&out, "(")

	s := strings.join(params[:], ", ")
	bytes.buffer_write_string(&out, s)
	delete(s)

	bytes.buffer_write_string(&out, ")")

	buf := to_string(e.body)
	defer bytes.buffer_destroy(&buf)
	bytes.buffer_write(&out, bytes.buffer_to_bytes(&buf))

	return out
}

call_expr_to_string :: proc(e: ^Call_Expr) -> bytes.Buffer {
	out: bytes.Buffer

	bufs: [dynamic]bytes.Buffer
	defer {
		for buf in &bufs {
			bytes.buffer_destroy(&buf)
		}
		delete(bufs)
	}

	for arg in e.arguments {
		append(&bufs, to_string(arg))
	}

	buf := to_string(e.function)
	defer bytes.buffer_destroy(&buf)
	bytes.buffer_write(&out, bytes.buffer_to_bytes(&buf))

	bytes.buffer_write_string(&out, "(")

	string_array: [dynamic]string
	defer delete(string_array)
	for b in &bufs {
		append(&string_array, bytes.buffer_to_string(&b))
	}
	s := strings.join(string_array[:], ", ")
	defer delete(s)
	bytes.buffer_write_string(&out, s)

	bytes.buffer_write_string(&out, ")")

	return out
}

string_literal_to_string :: proc(e: ^String_Literal) -> bytes.Buffer {
	out: bytes.Buffer

	bytes.buffer_write_string(&out, e.token.literal)

	return out
}

array_literal_to_string :: proc(e: ^Array_Literal) -> bytes.Buffer {
	out: bytes.Buffer

	bufs: [dynamic]bytes.Buffer
	defer {
		for buf in &bufs {
			bytes.buffer_destroy(&buf)
		}
		delete(bufs)
	}

	for elm in e.elements {
		append(&bufs, to_string(elm))
	}

	bytes.buffer_write_string(&out, "[")

	string_array: [dynamic]string
	defer delete(string_array)
	for b in &bufs {
		append(&string_array, bytes.buffer_to_string(&b))
	}
	s := strings.join(string_array[:], ", ")
	defer delete(s)
	bytes.buffer_write_string(&out, s)

	bytes.buffer_write_string(&out, "]")

	return out
}

index_expr_to_string :: proc(e: ^Index_Expr) -> bytes.Buffer {
	out: bytes.Buffer

	bytes.buffer_write_string(&out, "(")

	left_buf := to_string(e.left)
	defer bytes.buffer_destroy(&left_buf)
	bytes.buffer_write(&out, bytes.buffer_to_bytes(&left_buf))

	bytes.buffer_write_string(&out, "[")

	index_buf := to_string(e.index)
	defer bytes.buffer_destroy(&index_buf)
	bytes.buffer_write(&out, bytes.buffer_to_bytes(&index_buf))

	bytes.buffer_write_string(&out, "])")

	return out
}

hash_literal_to_string :: proc(e: ^Hash_Literal) -> bytes.Buffer {
	out: bytes.Buffer

	pairs: [dynamic]string
	defer delete(pairs)
	for key, value in &e.pairs {
		// key
		key_buf := to_string(key)
		defer bytes.buffer_destroy(&key_buf)
		bytes.buffer_write(&out, bytes.buffer_to_bytes(&key_buf))
		// value
		value_buf := to_string(value)
		defer bytes.buffer_destroy(&value_buf)
		bytes.buffer_write(&out, bytes.buffer_to_bytes(&value_buf))

		s := strings.join(
			[]string{bytes.buffer_to_string(&key_buf), ":", bytes.buffer_to_string(&value_buf)},
			"",
		)
		defer delete(s)

		append(&pairs, s)
	}

	bytes.buffer_write_string(&out, "{")

	s := strings.join(pairs[:], ", ")
	bytes.buffer_write_string(&out, s)
	delete(s)

	bytes.buffer_write_string(&out, "}")

	return out
}
