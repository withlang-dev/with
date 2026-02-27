//! expect-stdout: ok

// Behavior test: references and borrowing
// Tests: &x, &mut x, *ptr, ref/ptr type construction

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool
use Borrow
use Mir

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_ampersand_token:
    var tokens = lex("&x")
    assert(TokenList.tag_at(tokens, 0) == TK_AMPERSAND())
    assert(TokenList.tag_at(tokens, 1) == TK_IDENT())

fn test_mut_keyword:
    var tokens = lex("mut")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_MUT())

fn test_parse_ref:
    let src = "fn f:\n    &x\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_UNARY())
    assert(AstPool.get_data1(p.pool, body) == UOP_REF())

fn test_parse_deref:
    let src = "fn f:\n    *p\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_UNARY())
    assert(AstPool.get_data1(p.pool, body) == UOP_DEREF())

fn test_type_ref:
    var types = TypeTable.new()
    let r = TypeTable.add_ref(types, TYPE_I32(), 0)  // immutable ref
    assert(TypeTable.kind(types, r) == TK_REF())
    assert(TypeTable.get_data0(types, r) == TYPE_I32())
    assert(TypeTable.get_data1(types, r) == 0)  // not mut

fn test_type_mut_ref:
    var types = TypeTable.new()
    let r = TypeTable.add_ref(types, TYPE_I32(), 1)  // mutable ref
    assert(TypeTable.kind(types, r) == TK_REF())
    assert(TypeTable.get_data0(types, r) == TYPE_I32())
    assert(TypeTable.get_data1(types, r) == 1)  // mut

fn test_type_ptr:
    var types = TypeTable.new()
    let p = TypeTable.add_ptr(types, TYPE_I32(), 0)
    assert(TypeTable.kind(types, p) == TK_PTR())
    assert(TypeTable.get_data0(types, p) == TYPE_I32())

fn test_borrow_checker_clean:
    var types = TypeTable.new()
    var body = MirBody.new()
    MirBody.add_local(body, TYPE_I32(), 0)  // return place
    MirBody.add_block(body)
    MirBody.set_terminator(body, 0, TM_RETURN(), 0, 0, 0)
    var bc = BorrowChecker.new(body, types)
    BorrowChecker.check(bc)
    assert(BorrowChecker.error_count(bc) == 0)

fn main:
    test_ampersand_token()
    test_mut_keyword()
    test_parse_ref()
    test_parse_deref()
    test_type_ref()
    test_type_mut_ref()
    test_type_ptr()
    test_borrow_checker_clean()
    println("ok")
