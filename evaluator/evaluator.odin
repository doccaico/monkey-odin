package evaluator

import "core:fmt"
// import "core:bytes"
// import "core:mem"

import "../ast"
import "../object"

TRUE: ^object.Boolean
FALSE: ^object.Boolean

eval :: proc(node: ast.Node) -> ^object.Object {
	#partial switch v in node.derived {
	case ^ast.Program:
		return eval_stmts(v.statements)
	case ^ast.Expr_Stmt:
		return eval(v.expr)
	case ^ast.Int_Literal:
		obj := object.new_object(object.Integer)
		obj.value = v.value
		return obj
	case ^ast.Bool_Literal:
		return native_bool_to_boolean_object(v.value)
	case:
		panic("eval: unknown node type")
	}

	return nil
}

eval_stmts :: proc(stmts: [dynamic]^ast.Stmt) -> ^object.Object {
	result: ^object.Object

	for stmt in stmts {
		result = eval(stmt)
	}

	return result
}

native_bool_to_boolean_object :: proc(input: bool) -> ^object.Boolean {
	return (input) ? TRUE : FALSE
}

new_eval :: proc() {
	TRUE = object.new_object_boolean(true)
	FALSE = object.new_object_boolean(false)
}

delete_eval :: proc() {
	free(TRUE)
	free(FALSE)
}
