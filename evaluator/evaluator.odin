package evaluator

import "core:bytes"
import "core:fmt"
import "core:strings"
// import "core:bytes"
// import "core:mem"

import "../ast"
import "../object"

TRUE: ^object.Boolean
FALSE: ^object.Boolean
NULL: ^object.Null

args_array: [dynamic][dynamic]^object.Object
elements_array: [dynamic][dynamic]^object.Object
env_array: [dynamic]^object.Environment

eval :: proc(node: ast.Node, env: ^object.Environment) -> ^object.Object {
	#partial switch v in node.derived {
	case ^ast.Program:
		return eval_program(v, env)
	case ^ast.Expr_Stmt:
		return eval(v.expr, env)
	case ^ast.Int_Literal:
		obj := object.new_object(object.Integer)
		obj.value = v.value
		return obj
	case ^ast.Bool_Literal:
		return native_bool_to_boolean_object(v.value)
	case ^ast.Prefix_Expr:
		right := eval(v.right, env)
		if is_error(right) {
			return right
		}
		return eval_prefix_expr(v.operator, right)
	case ^ast.Infix_Expr:
		left := eval(v.left, env)
		if is_error(left) {
			return left
		}
		right := eval(v.right, env)
		if is_error(right) {
			return right
		}
		return eval_infix_expr(v.operator, left, right)
	case ^ast.Block_Stmt:
		return eval_block_stmt(v, env)
	case ^ast.If_Expr:
		return eval_if_expr(v, env)
	case ^ast.Return_Stmt:
		value := eval(v.return_value, env)
		if is_error(value) {
			return value
		}
		obj := object.new_object(object.Return_Value)
		obj.value = value
		return obj
	case ^ast.Let_Stmt:
		val := eval(v.value, env)
		if is_error(val) {
			return val
		}
		object.set(env, v.name.value, val)
	case ^ast.Ident:
		return eval_ident(v, env)
	case ^ast.Function_Literal:
		obj := object.new_object(object.Function)
		obj.parameters = v.parameters
		obj.env = env
		obj.body = v.body
		return obj
	case ^ast.Call_Expr:
		function := eval(v.function, env)
		if is_error(function) {
			return function
		}
		args := eval_exprs(v.arguments, env)
		append(&args_array, args)
		if len(args) == 1 && is_error(args[0]) {
			return args[0]
		}
		return apply_function(function, args)
	case ^ast.String_Literal:
		obj := object.new_object(object.String)
		obj.value = v.value
		return obj
	case ^ast.Array_Literal:
		elements := eval_exprs(v.elements, env)
		append(&elements_array, elements)
		if len(elements) == 1 && is_error(elements[0]) {
			return elements[0]
		}
		obj := object.new_object(object.Array)
		obj.elements = elements
		return obj
	case ^ast.Index_Expr:
		left := eval(v.left, env)
		if is_error(left) {
			return left
		}
		index := eval(v.index, env)
		if is_error(index) {
			return index
		}
		return eval_index_expr(left, index)
	case ^ast.Hash_Literal:
		return eval_hash_literal(v, env)
	case:
		panic("eval: unknown node type")
	}

	return nil
}

eval_program :: proc(program: ^ast.Program, env: ^object.Environment) -> ^object.Object {
	result: ^object.Object

	for stmt in program.statements {
		result = eval(stmt, env)

		if result == nil {
			continue
		}

		#partial switch v in result.derived {
		case ^object.Return_Value:
			return v.value
		case ^object.Error:
			return v
		}
	}

	return result
}

eval_block_stmt :: proc(block: ^ast.Block_Stmt, env: ^object.Environment) -> ^object.Object {
	result: ^object.Object

	for stmt in block.statements {
		result = eval(stmt, env)

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

	object.add_object(obj)

	return obj
}

new_eval :: proc() {
	TRUE = object.new_object_boolean(true)
	FALSE = object.new_object_boolean(false)
	NULL = object.new_object_null()
}

delete_eval :: proc() {
	free(TRUE)
	free(FALSE)
	free(NULL)

	for args in args_array {
		delete(args)
	}
	delete(args_array)

	for elements in elements_array {
		delete(elements)
	}
	delete(elements_array)

	for env in env_array {
		delete(env.store)
		free(env)
	}
	delete(env_array)

	for buffer in &object.buffer_array {
		bytes.buffer_destroy(&buffer)
	}
	delete(object.buffer_array)

	object.delete_object()
	delete(object.object_array)

	for elements in allocated_array {
		delete(elements)
	}
	delete(allocated_array)

	delete(builtins)
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
		return FALSE
	}
}

eval_minus_prefix_operator_expr :: proc(right: ^object.Object) -> ^object.Object {
	if object.type(right) != object.INTEGER_OBJ {
		return new_error("unknown operator: -%s", object.type(right))
	}

	value := right.derived.(^object.Integer).value

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
		return new_error(
			"type mismatch: %s %s %s",
			object.type(left),
			operator,
			object.type(right),
		)
	case object.type(left) == object.STRING_OBJ && object.type(right) == object.STRING_OBJ:
		return eval_string_infix_expr(operator, left, right)
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
	return obj
}

eval_if_expr :: proc(e: ^ast.If_Expr, env: ^object.Environment) -> ^object.Object {
	condition := eval(e.condition, env)
	if is_error(condition) {
		return condition
	}
	if is_truthy(condition) {
		return eval(e.consequence, env)
	} else if e.alternative != nil {
		return eval(e.alternative, env)
	} else {
		return NULL
	}
}

eval_ident :: proc(node: ^ast.Ident, env: ^object.Environment) -> ^object.Object {
	if val, ok := object.get(env, node.value); ok {
		return val
	}

	if builtin, ok := builtins[node.value]; ok {
		return builtin
	}

	return new_error(fmt.tprintf("identifier not found: %s", node.value))
}

eval_exprs :: proc(
	exprs: [dynamic]^ast.Expr,
	env: ^object.Environment,
) -> [dynamic]^object.Object {
	result: [dynamic]^object.Object
	for e in exprs {
		evaluated := eval(e, env)
		if is_error(evaluated) {
			// return []object.Object{evaluated} (Golang version)
			append(&result, evaluated)
			return result
		}
		append(&result, evaluated)
	}

	return result
}

apply_function :: proc(fn: ^object.Object, args: [dynamic]^object.Object) -> ^object.Object {
	#partial switch f in fn.derived {
	case ^object.Function:
		extended_env := extend_function_env(f, args)
		append(&env_array, extended_env)
		evaluated := eval(f.body, extended_env)
		return unwrap_return_value(evaluated)
	case ^object.Builtin:
		return f.fn(args)
	case:
		return new_error("not a function: %s", object.type(fn))
	}
}

extend_function_env :: proc(
	fn: ^object.Function,
	args: [dynamic]^object.Object,
) -> ^object.Environment {
	env := object.new_enclosed_environment(fn.env)

	for param, param_idx in fn.parameters {
		object.set(env, param.value, args[param_idx])
	}

	return env
}

unwrap_return_value :: proc(obj: ^object.Object) -> ^object.Object {
	if return_value, ok := obj.derived.(^object.Return_Value); ok {
		return return_value.value
	}
	return obj
}

eval_string_infix_expr :: proc(
	operator: string,
	left: ^object.Object,
	right: ^object.Object,
) -> ^object.Object {
	if operator != "+" {
		return new_error(
			"unknown operator: %s %s %s",
			object.type(left),
			operator,
			object.type(right),
		)
	}
	left_val := left.derived.(^object.String).value
	right_val := right.derived.(^object.String).value
	s := [?]string{left_val, right_val}

	obj := object.new_object(object.String)
	obj.value = strings.concatenate(s[:])
	obj.heap = true
	return obj
}

eval_index_expr :: proc(left: ^object.Object, index: ^object.Object) -> ^object.Object {
	switch {
	case object.type(left) == object.ARRAY_OBJ && object.type(index) == object.INTEGER_OBJ:
		return eval_array_index_expr(left, index)
	case:
		return new_error("index operator not supported: %s", object.type(left))
	}
}

eval_array_index_expr :: proc(array: ^object.Object, index: ^object.Object) -> ^object.Object {
	array_obj := array.derived.(^object.Array)
	idx := index.derived.(^object.Integer).value
	max := cast(i64)(len(array_obj.elements) - 1)

	if idx < 0 || idx > max {
		return NULL
	}

	return array_obj.elements[idx]
}

eval_hash_literal :: proc(node: ^ast.Hash_Literal, env: ^object.Environment) -> ^object.Object {
	pairs := make(map[object.Hash_Key]object.Hash_Pair)

	for key_node, value_node in node.pairs {
		key := eval(key_node, env)
		if is_error(key) {
			return key
		}

		hk: ^object.Object
		#partial switch v in key.derived {
		case ^object.Boolean:
			hk = v
		case ^object.Integer:
			hk = v
		case ^object.String:
			hk = v
		case:
			return new_error("unusable as hash key: %s", object.type(key))
		}

		value := eval(value_node, env)
		if is_error(value) {
			return value
		}

		hashed := object.hash_key(hk)
		pairs[hashed] = object.Hash_Pair {
			key   = key,
			value = value,
		}
	}

	obj := object.new_object(object.Hash)
	obj.pairs = pairs

	return obj
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
		return true
	}
}

is_error :: proc(obj: ^object.Object) -> bool {
	if obj != nil {
		return object.type(obj) == object.ERROR_OBJ
	}
	return false
}
