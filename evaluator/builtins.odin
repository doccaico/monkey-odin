package evaluator

import "../evaluator"
import "../object"

builtins := init_builtin_functions()

init_builtin_functions :: proc() -> map[string]^object.Builtin {
	bfs := map[string]object.BuiltinFunction {
		"len" = builtin_function_len,
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
	case ^object.String:
		obj := object.new_object(object.Integer)
		obj.value = cast(i64)len(arg.value)
		return obj
	case:
		return new_error("argument to `len` not supported, got %s", object.type(args[0]))
	}
}
