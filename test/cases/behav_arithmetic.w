//! expect-stdout: ok

// Behavior test: arithmetic operations
// Tests that the self-hosted compiler correctly handles arithmetic through
// the pipeline: Lexer → Parser → Sema → MIR → Codegen.

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool
use Mir
use MirBuild
use Codegen

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn parse(source: str) -> AstPool:
    var tokens = lex(source)
    var p = Parser.new(tokens, source)
    Parser.parse_module(p)
    p.pool

fn test_add_tokens:
    // "1 + 2" should tokenize to: int + int eof
    var tokens = lex("1 + 2")
    assert(TokenList.tag_at(tokens, 0) == TK_INT_LIT())
    assert(TokenList.tag_at(tokens, 1) == TK_PLUS())
    assert(TokenList.tag_at(tokens, 2) == TK_INT_LIT())

fn test_all_arith_ops:
    // Test all arithmetic operator tokens
    var tokens = lex("+ - * / %")
    assert(TokenList.tag_at(tokens, 0) == TK_PLUS())
    assert(TokenList.tag_at(tokens, 1) == TK_MINUS())
    assert(TokenList.tag_at(tokens, 2) == TK_STAR())
    assert(TokenList.tag_at(tokens, 3) == TK_SLASH())
    assert(TokenList.tag_at(tokens, 4) == TK_PERCENT())

fn test_compound_assign_tokens:
    var tokens = lex("+= -= *= /= %=")
    assert(TokenList.tag_at(tokens, 0) == TK_PLUS_EQ())
    assert(TokenList.tag_at(tokens, 1) == TK_MINUS_EQ())
    assert(TokenList.tag_at(tokens, 2) == TK_STAR_EQ())
    assert(TokenList.tag_at(tokens, 3) == TK_SLASH_EQ())
    assert(TokenList.tag_at(tokens, 4) == TK_PERCENT_EQ())

fn test_comparison_tokens:
    var tokens = lex("== != < > <= >=")
    assert(TokenList.tag_at(tokens, 0) == TK_EQ_EQ())
    assert(TokenList.tag_at(tokens, 1) == TK_BANG_EQ())
    assert(TokenList.tag_at(tokens, 2) == TK_LT())
    assert(TokenList.tag_at(tokens, 3) == TK_GT())
    assert(TokenList.tag_at(tokens, 4) == TK_LT_EQ())
    assert(TokenList.tag_at(tokens, 5) == TK_GT_EQ())

fn test_parse_binary_add:
    let src = "fn f:\n    1 + 2\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BINARY())
    assert(AstPool.get_data2(p.pool, body) == OP_ADD())
    let lhs = AstPool.get_data0(p.pool, body)
    let rhs = AstPool.get_data1(p.pool, body)
    assert(AstPool.kind(p.pool, lhs) == NK_INT_LIT())
    assert(AstPool.kind(p.pool, rhs) == NK_INT_LIT())

fn test_parse_binary_sub:
    let src = "fn f:\n    3 - 1\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BINARY())
    assert(AstPool.get_data2(p.pool, body) == OP_SUB())

fn test_parse_binary_mul:
    let src = "fn f:\n    4 * 5\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BINARY())
    assert(AstPool.get_data2(p.pool, body) == OP_MUL())

fn test_parse_binary_div:
    let src = "fn f:\n    10 / 2\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BINARY())
    assert(AstPool.get_data2(p.pool, body) == OP_DIV())

fn test_parse_binary_mod:
    let src = "fn f:\n    7 % 3\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BINARY())
    assert(AstPool.get_data2(p.pool, body) == OP_MOD())

fn test_sema_arith_types:
    // i32 + i32 → i32
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let lhs = AstPool.add_node(pool, NK_INT_LIT(), 0, 1, 1, 0, 0)
    let rhs = AstPool.add_node(pool, NK_INT_LIT(), 4, 5, 2, 0, 0)
    let add = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_ADD())
    let t = Sema.check_expr(s, add)
    assert(t == TYPE_I32())

fn test_sema_comparison_types:
    // i32 == i32 → bool
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let lhs = AstPool.add_node(pool, NK_INT_LIT(), 0, 1, 1, 0, 0)
    let rhs = AstPool.add_node(pool, NK_INT_LIT(), 4, 5, 2, 0, 0)
    let eq = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_EQ())
    let t = Sema.check_expr(s, eq)
    assert(t == TYPE_BOOL())
    // i32 < i32 → bool
    let lt = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_LT())
    let t2 = Sema.check_expr(s, lt)
    assert(t2 == TYPE_BOOL())
    // i32 != i32 → bool
    let neq = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_NEQ())
    let t3 = Sema.check_expr(s, neq)
    assert(t3 == TYPE_BOOL())

fn test_sema_negate:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let operand = AstPool.add_node(pool, NK_INT_LIT(), 1, 2, 42, 0, 0)
    let neg = AstPool.add_node(pool, NK_UNARY(), 0, 2, operand, UOP_NEGATE(), 0)
    let t = Sema.check_expr(s, neg)
    assert(t == TYPE_I32())

fn test_mir_arith_lowering:
    // Build: fn f: 1 + 2
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    let lhs = AstPool.add_node(pool, NK_INT_LIT(), 0, 1, 1, 0, 0)
    let rhs = AstPool.add_node(pool, NK_INT_LIT(), 4, 5, 2, 0, 0)
    let add = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_ADD())
    let name_sym = AstPool.add_string(pool, "f")
    let e0 = AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    let fn_node = AstPool.add_node(pool, NK_FN_DECL(), 0, 10, name_sym, add, e0)
    AstPool.add_decl(pool, fn_node)
    var types = TypeTable.new()
    var builder = MirBuilder.new(pool, types, "fn f:\n    1 + 2\n")
    let mir = MirBuilder.lower_fn(builder, fn_node)
    assert(MirBody.block_count(mir) >= 1)

fn test_codegen_arith:
    // Build a simple function and codegen it
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    let lhs = AstPool.add_node(pool, NK_INT_LIT(), 0, 1, 1, 0, 0)
    let rhs = AstPool.add_node(pool, NK_INT_LIT(), 4, 5, 2, 0, 0)
    let add = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_ADD())
    let name_sym = AstPool.add_string(pool, "f")
    let e0 = AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    let fn_node = AstPool.add_node(pool, NK_FN_DECL(), 0, 10, name_sym, add, e0)
    AstPool.add_decl(pool, fn_node)
    var types = TypeTable.new()
    var builder = MirBuilder.new(pool, types, "fn f:\n    1 + 2\n")
    let mir = MirBuilder.lower_fn(builder, fn_node)
    var cg = CodegenState.new(mir, types)
    CodegenState.gen_function(cg)
    assert(CodegenState.inst_count(cg) >= 1)

fn test_number_literals:
    // Decimal
    var tokens = lex("42")
    assert(TokenList.tag_at(tokens, 0) == TK_INT_LIT())
    // Hex
    var tokens2 = lex("0xFF")
    assert(TokenList.tag_at(tokens2, 0) == TK_INT_LIT())
    // Binary
    var tokens3 = lex("0b1010")
    assert(TokenList.tag_at(tokens3, 0) == TK_INT_LIT())
    // Octal
    var tokens4 = lex("0o77")
    assert(TokenList.tag_at(tokens4, 0) == TK_INT_LIT())
    // Float
    var tokens5 = lex("3.14")
    assert(TokenList.tag_at(tokens5, 0) == TK_FLOAT_LIT())

fn main:
    test_add_tokens()
    test_all_arith_ops()
    test_compound_assign_tokens()
    test_comparison_tokens()
    test_parse_binary_add()
    test_parse_binary_sub()
    test_parse_binary_mul()
    test_parse_binary_div()
    test_parse_binary_mod()
    test_sema_arith_types()
    test_sema_comparison_types()
    test_sema_negate()
    test_mir_arith_lowering()
    test_codegen_arith()
    test_number_literals()
    println("ok")
