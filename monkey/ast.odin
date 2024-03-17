package monkey

import "core:fmt"
import "core:intrinsics"
import "core:mem"

Any_Node :: union {
	^Program,

	// Stmts
	// ^Expr_Stmt,
	^Let_Stmt,
	// ^Return_Stmt,
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
	token:      Token,
	name:       ^Ident,
	value:      ^Expr,
}

// Exprs

Ident :: struct {
	using node: Expr,
	token:      Token,
	value:      string,
}

token_literal :: proc(node: Node) -> string {
	switch v in node.derived {
	case ^Program:
		return program_token_literal(v)
	// case ^Expr_Stmt: return expr_stmt_string(v)
	case ^Let_Stmt:
		return let_stmt_token_literal(v)
	// case ^Return_Stmt: return return_stmt_string(v)
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
		panic("unknown node type")
	}
}

// to_string :: proc(node: Node) -> string {
//     switch v in node.derived {
//         case ^Program: return program_string(v)
//         case ^Expr_Stmt: return expr_stmt_string(v)
//         case ^Let_Stmt: return let_stmt_string(v)
//         case ^Return_Stmt: return return_stmt_string(v)
//         case ^Block_Stmt: return block_stmt_string(v)
//         case ^Ident: return ident_string(v)
//         case ^Int_Literal: return int_literal_string(v)
//         case ^String_Literal: return string_literal_string(v)
//         case ^Bool_Literal: return bool_literal_string(v)
//         case ^Prefix_Expr: return prefix_expr_string(v)
//         case ^Infix_Expr: return infix_expr_string(v)
//         case ^If_Expr: return if_expr_string(v)
//         case ^Function_Literal: return function_expr_string(v)
//         case ^Call_Expr: return call_expr_string(v)
//         case ^Array_Literal: return array_expr_string(v)
//         case ^Index_Expr: return index_expr_string(v)
//         case ^Hash_Expr: return hash_expr_string(v)
//         case:
//             panic("unknown node type")
//     }
// }

program_token_literal :: proc(p: ^Program) -> string {
	if len(p.statements) > 0 {
		// return p.Statements[0].token_literal()
		return token_literal(p.statements[0])
	} else {
		return ""
	}
}

let_stmt_token_literal :: proc(s: ^Let_Stmt) -> string {
	return s.token.literal
}

ident_token_literal :: proc(e: ^Ident) -> string {
	return e.token.literal
}

new_node :: proc($T: typeid) -> ^T where intrinsics.type_has_field(T, "derived") {
	node := new(T)
	node.derived = node

	return node
}
