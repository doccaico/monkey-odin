package object

import "core:fmt"
import "core:intrinsics"

INTEGER_OBJ :: "INTEGER"
BOOLEAN_OBJ :: "BOOLEAN"
NULL_OBJ :: "NULL"

Any_Obj :: union {
	^Integer,
	^Boolean,
	^Null,
	// ^String,
	// ^Return_Value,
	// ^Error,
	// ^Function,
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


new_object :: proc($T: typeid) -> ^T where intrinsics.type_has_field(T, "derived") {
	obj := new(T)
	obj.derived = obj

	// fmt.printf("1. Object: %v\n", obj)
	// fmt.printf("2. Pointer: %p\n", obj)
	// fmt.println()

	return obj
}

delete_object :: proc(obj: ^Object) {
	#partial switch v in obj.derived {
	case ^Integer:
		free(v)
	case:
		panic("delete_object: unknown object type")
	}
}

type :: proc(obj: ^Object) -> ObjectType {
	switch v in obj.derived {
	case ^Integer:
		return integer_type(v)
	case ^Boolean:
		return boolean_type(v)
	case ^Null:
		return null_type(v)
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

inspect :: proc(obj: ^Object) -> string {
	switch v in obj.derived {
	case ^Integer:
		return integer_inspect(v)
	case ^Boolean:
		return boolean_inspect(v)
	case ^Null:
		return null_inspect(v)
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