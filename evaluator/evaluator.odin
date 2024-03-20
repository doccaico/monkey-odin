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
	case ^ast.Infix_Expr:
		left := eval(v.left)
		right := eval(v.right)
		return eval_infix_expr(v.operator, left, right)
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

eval_infix_expr :: proc(
	operator: string,
	left: ^object.Object,
	right: ^object.Object,
) -> ^object.Object {
	switch {
	case object.type(left) == object.INTEGER_OBJ && object.type(right) == object.INTEGER_OBJ:
		return eval_integer_infix_expr(operator, left, right)
	case operator == "==":
		return native_bool_to_boolean_object(left == right)
	case operator == "!=":
		return native_bool_to_boolean_object(left != right)
	case:
		return NULL
	}
}

eval_integer_infix_expr :: proc(
	operator: string,
	left: ^object.Object,
	right: ^object.Object,
) -> ^object.Object {
	lvalue := left.derived.(^object.Integer).value
	rvalue := right.derived.(^object.Integer).value
	obj: ^object.Object
	switch operator {
	case "+":
		obj = object.new_object(object.Integer)
		obj.derived.(^object.Integer).value = lvalue + rvalue
	case "-":
		obj = object.new_object(object.Integer)
		obj.derived.(^object.Integer).value = lvalue - rvalue
	case "*":
		obj = object.new_object(object.Integer)
		obj.derived.(^object.Integer).value = lvalue * rvalue
	case "/":
		obj = object.new_object(object.Integer)
		obj.derived.(^object.Integer).value = lvalue / rvalue
	case "<":
		obj = native_bool_to_boolean_object(lvalue < rvalue)
	case ">":
		obj = native_bool_to_boolean_object(lvalue > rvalue)
	case "==":
		obj = native_bool_to_boolean_object(lvalue == rvalue)
	case "!=":
		obj = native_bool_to_boolean_object(lvalue != rvalue)
	case:
		return NULL
	}
	free(left)
	free(right)
	return obj
}
