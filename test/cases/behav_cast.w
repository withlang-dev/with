//! expect-stdout: ok

// Behavior test: type casting (as)
// Tests: int↔int, int↔float, widening, narrowing

use Token
use Lexer
use Ast
use Type
use Codegen
use Sema
use InternPool
use Parser

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_as_keyword:
    var tokens = lex("x as i32")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT())
    assert(TokenList.tag_at(tokens, 1) == TK_KW_AS())
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT())

fn test_parse_cast:
    let src = "fn f:\n    42 as i64\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_CAST())

fn test_type_int_widening:
    var types = TypeTable.new()
    // i32 can widen to i64
    assert(TypeTable.is_int(types, TYPE_I32()))
    assert(TypeTable.is_int(types, TYPE_I64()))
    // All int types are numeric
    assert(TypeTable.is_numeric(types, TYPE_I8()))
    assert(TypeTable.is_numeric(types, TYPE_I16()))
    assert(TypeTable.is_numeric(types, TYPE_I32()))
    assert(TypeTable.is_numeric(types, TYPE_I64()))
    assert(TypeTable.is_numeric(types, TYPE_U8()))
    assert(TypeTable.is_numeric(types, TYPE_U16()))
    assert(TypeTable.is_numeric(types, TYPE_U32()))
    assert(TypeTable.is_numeric(types, TYPE_U64()))

fn test_type_float_checks:
    var types = TypeTable.new()
    assert(TypeTable.is_float(types, TYPE_F32()))
    assert(TypeTable.is_float(types, TYPE_F64()))
    assert(not TypeTable.is_float(types, TYPE_I32()))
    assert(TypeTable.is_numeric(types, TYPE_F32()))
    assert(TypeTable.is_numeric(types, TYPE_F64()))

fn test_type_non_numeric:
    var types = TypeTable.new()
    assert(not TypeTable.is_numeric(types, TYPE_BOOL()))
    assert(not TypeTable.is_numeric(types, TYPE_STR()))
    assert(not TypeTable.is_numeric(types, TYPE_VOID()))

fn test_codegen_cast_instructions:
    // Test the cast_instruction helper in Codegen
    var types = TypeTable.new()
    // i32 → i64 should be sext (sign extend)
    let inst = cast_instruction(types, TYPE_I32(), TYPE_I64())
    assert(inst == LI_SEXT())
    // i64 → i32 should be trunc
    let inst2 = cast_instruction(types, TYPE_I64(), TYPE_I32())
    assert(inst2 == LI_TRUNC())
    // i32 → f64 should be sitofp
    let inst3 = cast_instruction(types, TYPE_I32(), TYPE_F64())
    assert(inst3 == LI_SITOFP())
    // f64 → i32 should be fptosi
    let inst4 = cast_instruction(types, TYPE_F64(), TYPE_I32())
    assert(inst4 == LI_FPTOSI())
    // f32 → f64 should be fpext
    let inst5 = cast_instruction(types, TYPE_F32(), TYPE_F64())
    assert(inst5 == LI_FPEXT())
    // f64 → f32 should be fptrunc
    let inst6 = cast_instruction(types, TYPE_F64(), TYPE_F32())
    assert(inst6 == LI_FPTRUNC())
    // u32 → u64 should be zext
    let inst7 = cast_instruction(types, TYPE_U32(), TYPE_U64())
    assert(inst7 == LI_ZEXT())
    // u32 → f64 should be uitofp
    let inst8 = cast_instruction(types, TYPE_U32(), TYPE_F64())
    assert(inst8 == LI_UITOFP())

fn test_sema_type_compat_widening:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // i32 widens to i64
    assert(Sema.types_compatible(s, TYPE_I32(), TYPE_I64()))
    // f32 widens to f64
    assert(Sema.types_compatible(s, TYPE_F32(), TYPE_F64()))
    // But not str to i32
    assert(not Sema.types_compatible(s, TYPE_STR(), TYPE_I32()))

fn main:
    test_as_keyword()
    test_parse_cast()
    test_type_int_widening()
    test_type_float_checks()
    test_type_non_numeric()
    test_codegen_cast_instructions()
    test_sema_type_compat_widening()
    println("ok")
