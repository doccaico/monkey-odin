package evaluator

import "core:fmt"
// import "core:bytes"
// import "core:mem"

import "../ast"
import "../object"

TRUE: ^object.Boolean
FALSE: ^object.Boolean
NULL: ^object.Null

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
	case ^ast.Prefix_Expr:
		right := eval(v.right)
		return eval_prefix_expr(v.operator, right)
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
	NULL = object.new_object(object.Null)
}

delete_eval :: proc() {
	free(TRUE)
	free(FALSE)
	free(NULL)
}

eval_prefix_expr :: proc(operator: string, right: ^object.Object) -> ^object.Object {
	switch operator {
	case "!":
		return eval_bang_operator_expr(right)
	case "-":
		return eval_minus_prefix_operator_expr(right)
	case:
		return NULL
	}
}

eval_bang_operator_expr :: proc(right: ^object.Object) -> ^object.Object {
	switch right {
	case TRUE:
		return FALSE
	case FALSE:
		return TRUE
	case NULL:
		return TRUE
	case:
		free(right) // バグりそうな予感
		return FALSE
	}
}

eval_minus_prefix_operator_expr :: proc(right: ^object.Object) -> ^object.Object {
	if object.type(right) != object.INTEGER_OBJ {
		object.delete_object(right) // バグりそうな予感
		return NULL
	}

	value := right.derived.(^object.Integer).value
	free(right) // バグりそうな予感

	obj := object.new_object(object.Integer)
	obj.value = -value

	return obj
}
