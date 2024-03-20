package evaluator

// import "core:bytes"
import "core:fmt"
// import "core:mem"
import "core:testing"

import "../ast"
import "../object"
// import "../parser"

eval :: proc(node: ast.Node) -> ^object.Object {
	#partial switch v in node.derived {
	case ^ast.Program:
		return eval_stmts(v.statements)
	case ^ast.Expr_Stmt:
		return eval(v.expr)
	case ^ast.Int_Literal:
		obj := object.new_object(object.Integer)
		obj.value = v.value
		// fmt.printf("%p\n", obj)
		return obj
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
