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
		return eval_program(v)
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
		if is_error(right) {
			return right
		}
		return eval_prefix_expr(v.operator, right)
	case ^ast.Infix_Expr:
		left := eval(v.left)
		if is_error(left) {
			return left
		}
		right := eval(v.right)
		if is_error(right) {
			return right
		}
		return eval_infix_expr(v.operator, left, right)
	case ^ast.Block_Stmt:
		return eval_block_stmt(v)
	case ^ast.If_Expr:
		return eval_if_expr(v)
	case ^ast.Return_Stmt:
		value := eval(v.return_value)
		if is_error(value) {
			return value
		}
		obj := object.new_object(object.Return_Value)
		obj.value = value
		return obj
	case:
		panic("eval: unknown node type")
	}
	return nil
}

eval_program :: proc(program: ^ast.Program) -> ^object.Object {
	result: ^object.Object

	for stmt in program.statements {
		result = eval(stmt)

		#partial switch v in result.derived {
		case ^object.Integer:
			object.delete_object(v)
		case ^object.Return_Value:
			ret := v.value
			object.delete_object(v.value)
			object.delete_object(v)
			return ret
		case ^object.Error:
			ret := result
			object.delete_object(v)
			return ret
		}
	}

	return result
}

eval_block_stmt :: proc(block: ^ast.Block_Stmt) -> ^object.Object {
	result: ^object.Object

	for stmt in block.statements {
		result = eval(stmt)

		if result != nil {
			rt := object.type(result)
			if rt == object.RETURN_VALUE_OBJ || rt == object.ERROR_OBJ {
				return result
			}
		}
	}

	return result
}

native_bool_to_boolean_object :: proc(input: bool) -> ^object.Boolean {
	return (input) ? TRUE : FALSE
}

new_error :: proc(format: string, args: ..any) -> ^object.Error {
	obj := new(object.Error)
	obj.derived = obj
	obj.message = fmt.tprintf(format, ..args)

	// fmt.printf("1. Error Object: %v\n", obj)
	// fmt.printf("2. Pointer: %p\n", obj)
	// fmt.println()

	return obj
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
		return new_error("unknown operator: %s%s", operator, object.type(right))
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
		return new_error("unknown operator: -%s", object.type(right))
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
	case object.type(left) != object.type(right):
		object.delete_object(left)
		object.delete_object(right)
		return new_error(
			"type mismatch: %s %s %s",
			object.type(left),
			operator,
			object.type(right),
		)
	case:
		return new_error(
			"unknown operator: %s %s %s",
			object.type(left),
			operator,
			object.type(right),
		)
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
		return new_error(
			"unknown operator: %s %s %s",
			object.type(left),
			operator,
			object.type(right),
		)
	}
	free(left)
	free(right)
	return obj
}

eval_if_expr :: proc(e: ^ast.If_Expr) -> ^object.Object {
	condition := eval(e.condition)
	if is_error(condition) {
		return condition
	}
	if is_truthy(condition) {
		return eval(e.consequence)
	} else if e.alternative != nil {
		return eval(e.alternative)
	} else {
		return NULL
	}
}

is_truthy :: proc(obj: ^object.Object) -> bool {
	switch obj {
	case NULL:
		return false
	case TRUE:
		return true
	case FALSE:
		return false
	case:
		object.delete_object(obj)
		return true
	}
}

is_error :: proc(obj: ^object.Object) -> bool {
	if obj != nil {
		return object.type(obj) == object.ERROR_OBJ
	}
	return false
}
