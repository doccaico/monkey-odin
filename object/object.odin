package object

import "core:bytes"
import "core:fmt"
import "core:intrinsics"
import "core:strings"

import "../ast"

INTEGER_OBJ :: "INTEGER"
BOOLEAN_OBJ :: "BOOLEAN"
NULL_OBJ :: "NULL"
RETURN_VALUE_OBJ :: "RETURN_VALUE"
ERROR_OBJ :: "ERROR"
FUNCTION_OBJ :: "FUNCTION"

object_array: [dynamic]^Object

Any_Obj :: union {
	^Integer,
	^Boolean,
	^Null,
	^Return_Value,
	^Error,
	^Function,
	// ^String,
	// ^Builtin,
	// ^Array,
	// ^Hash_Map,
}

ObjectType :: distinct string

Object :: struct {
	derived: Any_Obj,
}

Integer :: struct {
	using obj: Object,
	value:     i64,
}

Boolean :: struct {
	using obj: Object,
	value:     bool,
}

Null :: struct {
	using obj: Object,
}

Return_Value :: struct {
	using obj: Object,
	value:     ^Object,
}

Error :: struct {
	using obj: Object,
	message:   string,
}

Function :: struct {
	using obj:  Object,
	parameters: [dynamic]^ast.Ident,
	body:       ^ast.Block_Stmt,
	env:        ^Environment,
}

new_object :: proc($T: typeid) -> ^T where intrinsics.type_has_field(T, "derived") {
	obj := new(T)
	obj.derived = obj

	// fmt.printf("1. Object: %v\n", obj)
	// fmt.printf("2. Pointer: %p\n", obj)
	// fmt.println()

	add_object(obj)

	return obj
}

new_object_boolean :: proc(b: bool) -> ^Boolean {
	obj := new(Boolean)
	obj.derived = obj
	obj.value = b

	// fmt.printf("1. Object: %v\n", obj)
	// fmt.printf("2. Pointer: %p\n", obj)
	// fmt.println()

	return obj
}

new_object_null :: proc() -> ^Null {
	obj := new(Null)
	obj.derived = obj

	return obj
}

delete_object :: proc() {
	for obj in object_array {
		#partial switch v in obj.derived {
		case ^Integer:
			free(v)
		case ^Return_Value:
			free(v)
		case ^Error:
			free(v)
		case ^Function:
			free(v)
		case:
			panic("delete_object: unknown object type")
		}
	}
}

add_object :: proc(obj: ^Object) {
	append(&object_array, obj)
}

type :: proc(obj: ^Object) -> ObjectType {
	switch v in obj.derived {
	case ^Integer:
		return integer_type(v)
	case ^Boolean:
		return boolean_type(v)
	case ^Null:
		return null_type(v)
	case ^Return_Value:
		return return_value_type(v)
	case ^Error:
		return error_type(v)
	case ^Function:
		return function_type(v)
	case:
		panic("type: unknown object type")
	}
}

integer_type :: proc(obj: ^Integer) -> ObjectType {
	return INTEGER_OBJ
}

boolean_type :: proc(obj: ^Boolean) -> ObjectType {
	return BOOLEAN_OBJ
}

null_type :: proc(obj: ^Null) -> ObjectType {
	return NULL_OBJ
}

return_value_type :: proc(obj: ^Return_Value) -> ObjectType {
	return RETURN_VALUE_OBJ
}

error_type :: proc(obj: ^Error) -> ObjectType {
	return ERROR_OBJ
}

function_type :: proc(obj: ^Function) -> ObjectType {
	return FUNCTION_OBJ
}

inspect :: proc(obj: ^Object) -> string {
	switch v in obj.derived {
	case ^Integer:
		return integer_inspect(v)
	case ^Boolean:
		return boolean_inspect(v)
	case ^Null:
		return null_inspect(v)
	case ^Return_Value:
		return return_value_inspect(v)
	case ^Error:
		return error_inspect(v)
	case ^Function:
		return function_inspect(v)
	case:
		panic("inspect: unknown object type")
	}
}

integer_inspect :: proc(obj: ^Integer) -> string {
	return fmt.tprintf("%d", obj.value)
}

boolean_inspect :: proc(obj: ^Boolean) -> string {
	return fmt.tprintf("%t", obj.value)
}

null_inspect :: proc(obj: ^Null) -> string {
	return "null"
}

return_value_inspect :: proc(obj: ^Return_Value) -> string {
	return inspect(obj.value)
}

error_inspect :: proc(obj: ^Error) -> string {
	return fmt.tprintf("ERROR: %s", obj.message)
}

function_inspect :: proc(obj: ^Function) -> string {
	out: bytes.Buffer

	params: [dynamic]string
	defer delete(params)

	for p in obj.parameters {

		buf := ast.to_string(p)
		defer bytes.buffer_destroy(&buf)
		append(&params, bytes.buffer_to_string(&buf))
	}

	bytes.buffer_write_string(&out, "fn")
	bytes.buffer_write_string(&out, "(")

	s := strings.join(params[:], ", ")
	bytes.buffer_write_string(&out, s)
	delete(s)

	bytes.buffer_write_string(&out, ") {\n")

	buf := ast.to_string(obj.body)
	defer bytes.buffer_destroy(&buf)
	bytes.buffer_write(&out, bytes.buffer_to_bytes(&buf))

	bytes.buffer_write_string(&out, "\n}")

	// defer bytes.buffer_destroy(&buf)
	return bytes.buffer_to_string(&out)
}
