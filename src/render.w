// render — AST and MIR pretty-printer for the With compiler.
//
// Utility module (snake_case) for debug output.
// Produces human-readable text from AST nodes and MIR bodies.
//
// Ref: bootstrap/render.zig (stub)

use Ast
use Type
use Mir

// ── AST node kind names ──────────────────────────────────────────────

fn node_kind_name(kind: i32) -> str:
    if kind == NK_FN_DECL() then "FnDecl"
    else if kind == NK_TYPE_DECL() then "TypeDecl"
    else if kind == NK_USE_DECL() then "UseDecl"
    else if kind == NK_LET_DECL() then "LetDecl"
    else if kind == NK_EXTERN_FN() then "ExternFn"
    else if kind == NK_C_IMPORT() then "CImport"
    else if kind == NK_TRAIT_DECL() then "TraitDecl"
    else if kind == NK_IMPL_DECL() then "ImplDecl"
    else if kind == NK_INT_LIT() then "IntLit"
    else if kind == NK_FLOAT_LIT() then "FloatLit"
    else if kind == NK_STRING_LIT() then "StringLit"
    else if kind == NK_BOOL_LIT() then "BoolLit"
    else if kind == NK_IDENT() then "Ident"
    else if kind == NK_BINARY() then "Binary"
    else if kind == NK_UNARY() then "Unary"
    else if kind == NK_CALL() then "Call"
    else if kind == NK_FIELD_ACCESS() then "FieldAccess"
    else if kind == NK_INDEX() then "Index"
    else if kind == NK_BLOCK() then "Block"
    else if kind == NK_IF_EXPR() then "IfExpr"
    else if kind == NK_RETURN() then "Return"
    else if kind == NK_LET_BINDING() then "LetBinding"
    else if kind == NK_ASSIGN() then "Assign"
    else if kind == NK_WHILE() then "While"
    else if kind == NK_LOOP() then "Loop"
    else if kind == NK_FOR() then "For"
    else if kind == NK_BREAK() then "Break"
    else if kind == NK_CONTINUE() then "Continue"
    else if kind == NK_MATCH() then "Match"
    else if kind == NK_TUPLE() then "Tuple"
    else if kind == NK_ARRAY_LIT() then "ArrayLit"
    else if kind == NK_STRUCT_LIT() then "StructLit"
    else if kind == NK_CLOSURE() then "Closure"
    else if kind == NK_CAST() then "Cast"
    else if kind == NK_DEFER() then "Defer"
    else if kind == NK_PIPELINE() then "Pipeline"
    else if kind == NK_RANGE() then "Range"
    else if kind == NK_GROUPED() then "Grouped"
    else "Unknown"

// ── Binary op names ──────────────────────────────────────────────────

fn binop_name(op: i32) -> str:
    if op == OP_ADD() then "+"
    else if op == OP_SUB() then "-"
    else if op == OP_MUL() then "*"
    else if op == OP_DIV() then "/"
    else if op == OP_MOD() then "%"
    else if op == OP_EQ() then "=="
    else if op == OP_NEQ() then "!="
    else if op == OP_LT() then "<"
    else if op == OP_GT() then ">"
    else if op == OP_LTE() then "<="
    else if op == OP_GTE() then ">="
    else if op == OP_AND() then "and"
    else if op == OP_OR() then "or"
    else if op == OP_BIT_AND() then "&"
    else if op == OP_BIT_OR() then "|"
    else if op == OP_BIT_XOR() then "^"
    else if op == OP_SHL() then "<<"
    else if op == OP_SHR() then ">>"
    else if op == OP_DEFAULT() then "??"
    else if op == OP_CONCAT() then "++"
    else "?"

// ── Type kind names ──────────────────────────────────────────────────

fn type_kind_name(kind: i32) -> str:
    if kind == TK_ERROR() then "error"
    else if kind == TK_UNIT() then "unit"
    else if kind == TK_BOOL() then "bool"
    else if kind == TK_INT() then "int"
    else if kind == TK_FLOAT() then "float"
    else if kind == TK_STR() then "str"
    else if kind == TK_NEVER() then "never"
    else if kind == TK_VOID() then "void"
    else if kind == TK_STRUCT() then "struct"
    else if kind == TK_ENUM() then "enum"
    else if kind == TK_ARRAY() then "array"
    else if kind == TK_SLICE() then "slice"
    else if kind == TK_TUPLE() then "tuple"
    else if kind == TK_FN() then "fn"
    else if kind == TK_PTR() then "ptr"
    else if kind == TK_REF() then "ref"
    else if kind == TK_ALIAS() then "alias"
    else if kind == TK_GENERIC_PARAM() then "generic_param"
    else if kind == TK_TRAIT_OBJ() then "trait_obj"
    else if kind == TK_OPTION() then "Option"
    else if kind == TK_RESULT() then "Result"
    else if kind == TK_RANGE() then "Range"
    else "?"

// ── Builtin type names ───────────────────────────────────────────────

fn type_name(types: TypeTable, type_id: i32) -> str:
    if type_id == TYPE_ERROR() then "error"
    else if type_id == TYPE_UNIT() then "()"
    else if type_id == TYPE_BOOL() then "bool"
    else if type_id == TYPE_I8() then "i8"
    else if type_id == TYPE_I16() then "i16"
    else if type_id == TYPE_I32() then "i32"
    else if type_id == TYPE_I64() then "i64"
    else if type_id == TYPE_U8() then "u8"
    else if type_id == TYPE_U16() then "u16"
    else if type_id == TYPE_U32() then "u32"
    else if type_id == TYPE_U64() then "u64"
    else if type_id == TYPE_F32() then "f32"
    else if type_id == TYPE_F64() then "f64"
    else if type_id == TYPE_STR() then "str"
    else if type_id == TYPE_NEVER() then "!"
    else if type_id == TYPE_VOID() then "void"
    else type_kind_name(TypeTable.kind(types, type_id))

// ── MIR statement names ──────────────────────────────────────────────

fn stmt_kind_name(kind: i32) -> str:
    if kind == SK_ASSIGN() then "Assign"
    else if kind == SK_DROP() then "Drop"
    else if kind == SK_NOP() then "Nop"
    else "?"

fn terminator_kind_name(kind: i32) -> str:
    if kind == TM_GOTO() then "Goto"
    else if kind == TM_SWITCH_INT() then "SwitchInt"
    else if kind == TM_RETURN() then "Return"
    else if kind == TM_UNREACHABLE() then "Unreachable"
    else if kind == TM_CALL() then "Call"
    else if kind == TM_DROP() then "Drop"
    else if kind == TM_ASSERT() then "Assert"
    else "?"

// ── AST printing ─────────────────────────────────────────────────────

fn print_ast_summary(pool: AstPool) -> void:
    let nc = AstPool.node_count(pool)
    let dc = AstPool.decl_count(pool)
    println("AST: {nc} nodes, {dc} declarations")

fn print_mir_summary(body: MirBody) -> void:
    let lc = MirBody.local_count(body)
    let bc = MirBody.block_count(body)
    let sc = MirBody.stmt_count(body)
    println("MIR: {lc} locals, {bc} blocks, {sc} statements")
