package evaluator

import "core:fmt"

import "../evaluator"
import "../object"

allocated_array: [dynamic][dynamic]^object.Object
builtins := init_builtin_functions()

init_builtin_functions :: proc() -> map[string]^object.Builtin {
	bfs := map[string]object.BuiltinFunction {
		"len"   = builtin_function_len,
		"first" = builtin_function_first,
		"last"  = builtin_function_last,
		"rest"  = builtin_function_rest,
		"push"  = builtin_function_push,
	}
	defer delete(bfs)

	builtins: map[string]^object.Builtin

	for key in bfs {
		obj := new(object.Builtin)
		obj.derived = obj
		obj.fn = bfs[key]
		builtins[key] = obj
	}

	return builtins
}

builtin_function_len :: proc(args: [dynamic]^object.Object) -> ^object.Object {
	if len(args) != 1 {
		return new_error("wrong number of arguments. got=%d, want=1", len(args))
	}
	#partial switch arg in args[0].derived {
	case ^object.Array:
		obj := object.new_object(object.Integer)
		obj.value = cast(i64)len(arg.elements)
		return obj
	case ^object.String:
		obj := object.new_object(object.Integer)
		obj.value = cast(i64)len(arg.value)
		return obj
	case:
		return new_error("argument to `len` not supported, got %s", object.type(args[0]))
	}
}

builtin_function_first :: proc(args: [dynamic]^object.Object) -> ^object.Object {
	if len(args) != 1 {
		return new_error("wrong number of arguments. got=%d, want=1", len(args))
	}
	if object.type(args[0]) != object.ARRAY_OBJ {
		return new_error("argument to `first` must be ARRAY, got %s", object.type(args[0]))
	}

	arr := args[0].derived.(^object.Array)
	if len(arr.elements) > 0 {
		return arr.elements[0]
	}

	return NULL
}

builtin_function_last :: proc(args: [dynamic]^object.Object) -> ^object.Object {
	if len(args) != 1 {
		return new_error("wrong number of arguments. got=%d, want=1", len(args))
	}
	if object.type(args[0]) != object.ARRAY_OBJ {
		return new_error("argument to `last` must be ARRAY, got %s", object.type(args[0]))
	}

	arr := args[0].derived.(^object.Array)
	length := len(arr.elements)
	if length > 0 {
		return arr.elements[length - 1]
	}

	return NULL
}

builtin_function_rest :: proc(args: [dynamic]^object.Object) -> ^object.Object {
	if len(args) != 1 {
		return new_error("wrong number of arguments. got=%d, want=1", len(args))
	}
	if object.type(args[0]) != object.ARRAY_OBJ {
		return new_error("argument to `rest` must be ARRAY, got %s", object.type(args[0]))
	}

	arr := args[0].derived.(^object.Array)
	length := len(arr.elements)
	if length > 0 {
		new_elements := make([dynamic]^object.Object, length - 1, length - 1)
		for e, i in arr.elements[1:length] {
			new_elements[i] = e
		}

		append(&allocated_array, new_elements)

		obj := object.new_object(object.Array)
		obj.elements = new_elements
		return obj
	}

	return NULL
}

builtin_function_push :: proc(args: [dynamic]^object.Object) -> ^object.Object {
	if len(args) != 2 {
		return new_error("wrong number of arguments. got=%d, want=2", len(args))
	}
	if object.type(args[0]) != object.ARRAY_OBJ {
		return new_error("argument to `push` must be ARRAY, got %s", object.type(args[0]))
	}

	arr := args[0].derived.(^object.Array)
	length := len(arr.elements)

	new_elements := make([dynamic]^object.Object, length + 1, length + 1)
	for e, i in arr.elements {
		new_elements[i] = e
	}
	new_elements[length] = args[1]

	append(&allocated_array, new_elements)

	obj := object.new_object(object.Array)
	obj.elements = new_elements
	return obj
}
