use Lexer
use Parser
use Ast
use InternPool
use Diagnostic

fn parse_module(src: str) -> AstPool:
    var lexer = Lexer.init(src, 0)
    let tokens = lexer.tokenize()
    var intern = InternPool.init()
    var diags = DiagnosticList.init()
    var parser = Parser.init(tokens, src, 0, intern, diags)
    let pool = parser.parse_module()
    if parser.diags.has_errors():
        assert(false)
    pool

fn test_char_literal_lowering:
    let src = "fn f:\n    '\\n'\n"
    let pool = parse_module(src)
    assert(pool.decl_count() == 1)
    let decl = pool.get_decl(0)
    let body = pool.get_data1(decl)
    assert(pool.kind(body) == NK_INT_LIT())
    assert(pool.get_data0(body) == 10)

fn test_precedence:
    let src = "fn f:\n    1 + 2 * 3\n"
    let pool = parse_module(src)
    let decl = pool.get_decl(0)
    let body = pool.get_data1(decl)
    assert(pool.kind(body) == NK_BINARY())
    assert(pool.get_data0(body) == OP_ADD())
    let rhs = pool.get_data2(body)
    assert(pool.kind(rhs) == NK_BINARY())
    assert(pool.get_data0(rhs) == OP_MUL())

fn test_fn_metadata:
    let src = "fn add(a: i32, b: i32) -> i32:\n    a + b\n"
    let pool = parse_module(src)
    let decl = pool.get_decl(0)
    let meta = pool.find_fn_meta(decl)
    assert(meta >= 0)
    assert(pool.fn_meta_param_count(meta) == 2)
    let ret_ty = pool.fn_meta_ret(meta)
    assert(pool.kind(ret_ty) == NK_TYPE_NAMED())

fn test_type_param_layout:
    let src = "fn id[T: Show + Hash](x: T) -> T:\n    x\n"
    let pool = parse_module(src)
    let decl = pool.get_decl(0)
    let meta = pool.find_fn_meta(decl)
    assert(meta >= 0)
    assert(pool.fn_meta_tp_count(meta) == 1)
    let tp_start = pool.fn_meta_tp_start(meta)
    let bound_count = pool.get_extra(tp_start + 1)
    assert(bound_count == 2)

fn test_local_let_type_annotation_storage:
    let src = "fn f:\n    let x: i32 = 1\n    x\n"
    let pool = parse_module(src)
    let decl = pool.get_decl(0)
    let body = pool.get_data1(decl)
    assert(pool.kind(body) == NK_BLOCK())
    let stmt_start = pool.get_data0(body)
    let let_stmt = pool.get_extra(stmt_start)
    assert(pool.kind(let_stmt) == NK_LET_BINDING())
    let flags = pool.get_data2(let_stmt)
    let encoded = flags / 2
    assert(encoded > 0)
    let ty_node = pool.get_extra(encoded - 1)
    assert(pool.kind(ty_node) == NK_TYPE_NAMED())

fn main:
    test_char_literal_lowering()
    test_precedence()
    test_fn_metadata()
    test_type_param_layout()
    test_local_let_type_annotation_storage()
    println("ok")
