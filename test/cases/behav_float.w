//! expect-stdout: ok

// Behavior test: floating point
// Tests: f32/f64 types, float literals, float arithmetic codegen

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool
use Codegen

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_float_literal_token:
    var tokens = lex("3.14")
    assert(TokenList.tag_at(tokens, 0) == TK_FLOAT_LIT())

fn test_float_with_zero:
    var tokens = lex("0.0")
    assert(TokenList.tag_at(tokens, 0) == TK_FLOAT_LIT())

fn test_parse_float_lit:
    let src = "fn f:\n    3.14\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_FLOAT_LIT())

fn test_sema_float_type:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let n = AstPool.add_node(pool, NK_FLOAT_LIT(), 0, 4, 0, 0, 0)
    let t = Sema.check_expr(s, n)
    assert(t == TYPE_F64())

fn test_type_float_properties:
    var types = TypeTable.new()
    assert(TypeTable.is_float(types, TYPE_F32()) == true)
    assert(TypeTable.is_float(types, TYPE_F64()) == true)
    assert(TypeTable.is_float(types, TYPE_I32()) == false)
    assert(TypeTable.is_numeric(types, TYPE_F32()) == true)
    assert(TypeTable.is_copy(types, TYPE_F32()) == true)
    assert(TypeTable.is_copy(types, TYPE_F64()) == true)

fn test_codegen_float_ops:
    var types = TypeTable.new()
    // Float add
    let op = binop_to_llvm(OP_ADD(), TYPE_F64())
    assert(op == LI_FADD())
    // Float sub
    let op2 = binop_to_llvm(OP_SUB(), TYPE_F64())
    assert(op2 == LI_FSUB())
    // Float mul
    let op3 = binop_to_llvm(OP_MUL(), TYPE_F64())
    assert(op3 == LI_FMUL())
    // Float div
    let op4 = binop_to_llvm(OP_DIV(), TYPE_F64())
    assert(op4 == LI_FDIV())
    // Int add (for comparison)
    let op5 = binop_to_llvm(OP_ADD(), TYPE_I32())
    assert(op5 == LI_ADD())

fn main:
    test_float_literal_token()
    test_float_with_zero()
    test_parse_float_lit()
    test_sema_float_type()
    test_type_float_properties()
    test_codegen_float_ops()
    println("ok")
