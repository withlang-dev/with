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

fn parse_module_allow_errors(src: str) -> (AstPool, i32):
    var lexer = Lexer.init(src, 0)
    let tokens = lexer.tokenize()
    var intern = InternPool.init()
    var diags = DiagnosticList.init()
    var parser = Parser.init(tokens, src, 0, intern, diags)
    let pool = parser.parse_module()
    (pool, parser.diags.count())

fn test_char_literal_lowering:
    let src = "fn f:\n    '\\n'\n"
    let pool = parse_module(src)
    assert(pool.decl_count() == 1)
    let decl = pool.get_decl(0)
    let body = pool.get_data1(decl)
    assert(pool.kind(body) == NodeKind.NK_INT_LIT())
    assert(pool.get_data0(body) == 10)

fn test_byte_char_literal_lowering:
    let src = "fn f:\n    b'\\x41'\n"
    let pool = parse_module(src)
    assert(pool.decl_count() == 1)
    let decl = pool.get_decl(0)
    let body = pool.get_data1(decl)
    assert(pool.kind(body) == NodeKind.NK_INT_LIT())
    assert(pool.get_data0(body) == 65)

fn test_precedence:
    let src = "fn f:\n    1 + 2 * 3\n"
    let pool = parse_module(src)
    let decl = pool.get_decl(0)
    let body = pool.get_data1(decl)
    assert(pool.kind(body) == NodeKind.NK_BINARY())
    assert(pool.get_data0(body) == BinaryOp.OP_ADD)
    let rhs = pool.get_data2(body)
    assert(pool.kind(rhs) == NodeKind.NK_BINARY())
    assert(pool.get_data0(rhs) == BinaryOp.OP_MUL)

fn test_fn_metadata:
    let src = "fn add(a: i32, b: i32) -> i32:\n    a + b\n"
    let pool = parse_module(src)
    let decl = pool.get_decl(0)
    let meta = pool.find_fn_meta(decl)
    assert(meta >= 0)
    assert(pool.fn_meta_param_count(meta) == 2)
    let ret_ty = pool.fn_meta_ret(meta)
    assert(pool.kind(ret_ty) == NodeKind.NK_TYPE_NAMED())

fn test_callconv_metadata_unquotes_string_literal:
    let src = "@[callconv(\"c\")]\nfn visit(x: i32) -> i32:\n    x\n"
    var lexer = Lexer.init(src, 0)
    let tokens = lexer.tokenize()
    var intern = InternPool.init()
    var diags = DiagnosticList.init()
    var parser = Parser.init(tokens, src, 0, intern, diags)
    let pool = parser.parse_module()
    assert(not parser.diags.has_errors())
    intern = parser.intern
    let decl = pool.get_decl(0)
    let meta = pool.find_fn_meta(decl)
    assert(meta >= 0)
    let cc_sym = pool.fn_meta_tp_start(meta)
    assert(cc_sym != 0)
    assert(intern.resolve(cc_sym) == "c")

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
    assert(pool.kind(body) == NodeKind.NK_BLOCK())
    let stmt_start = pool.get_data0(body)
    let let_stmt = pool.get_extra(stmt_start)
    assert(pool.kind(let_stmt) == NodeKind.NK_LET_BINDING())
    let flags = pool.get_data2(let_stmt)
    let encoded = flags / 2
    assert(encoded > 0)
    let ty_node = pool.get_extra(encoded - 1)
    assert(pool.kind(ty_node) == NodeKind.NK_TYPE_NAMED())

fn test_compose_lowering:
    let src = "fn f:\n    let add_one = x => x + 1\n    let double = x => x * 2\n    add_one >> double\n"
    let pool = parse_module(src)
    let decl = pool.get_decl(0)
    let body = pool.get_data1(decl)
    assert(pool.kind(body) == NodeKind.NK_BLOCK())
    let tail = pool.get_data2(body)
    assert(pool.kind(tail) == NodeKind.NK_CLOSURE())

fn test_type_expr_impl_for:
    let src = "fn f(x: impl Show for i32) -> dyn Show:\n    x\n"
    let pool = parse_module(src)
    let decl = pool.get_decl(0)
    let meta = pool.find_fn_meta(decl)
    assert(meta >= 0)
    let param_start = pool.fn_meta_param_start(meta)
    let param_type = pool.get_extra(param_start + 1)
    assert(pool.kind(param_type) == NodeKind.NK_TYPE_TRAIT_OBJ())
    assert(pool.get_data1(param_type) == TYPE_TRAIT_OBJECT_IMPL)
    let ret_type = pool.fn_meta_ret(meta)
    assert(pool.kind(ret_type) == NodeKind.NK_TYPE_TRAIT_OBJ())
    assert(pool.get_data1(ret_type) == TYPE_TRAIT_OBJECT_DYN)

fn test_type_expr_slice_alt:
    let src = "fn f(x: [i32]) -> []i32:\n    x\n"
    let pool = parse_module(src)
    let decl = pool.get_decl(0)
    let meta = pool.find_fn_meta(decl)
    assert(meta >= 0)
    let param_start = pool.fn_meta_param_start(meta)
    let param_type = pool.get_extra(param_start + 1)
    assert(pool.kind(param_type) == NodeKind.NK_TYPE_SLICE())
    let ret_type = pool.fn_meta_ret(meta)
    assert(pool.kind(ret_type) == NodeKind.NK_TYPE_SLICE())

fn test_trait_layout_contains_assoc_and_methods:
    let src = "trait Maker =\n    type Item: Show = i32\n    fn make(x: i32) -> i32\n"
    let pool = parse_module(src)
    assert(pool.decl_count() == 1)
    let decl = pool.get_decl(0)
    assert(pool.kind(decl) == NodeKind.NK_TRAIT_DECL())
    let extra_start = pool.get_data1(decl)
    let assoc_count = pool.get_extra(extra_start)
    assert(assoc_count == 1)
    let method_count_idx = extra_start + 1 + 1 + 1 + 1 + 1
    let method_count = pool.get_extra(method_count_idx)
    assert(method_count == 1)

fn test_recovery_to_next_top_level_decl:
    let src = "fn a:\n    1\nfor\nfn b:\n    2\n"
    let result = parse_module_allow_errors(src)
    let pool = result.0
    let diag_count = result.1
    assert(diag_count > 0)
    assert(pool.decl_count() == 2)

fn test_trailing_commas_call_and_type_params:
    let src = "fn f[T,](x: Vec[i32,],) -> i32:\n    add(1, 2,)\n"
    let pool = parse_module(src)
    let decl = pool.get_decl(0)
    let meta = pool.find_fn_meta(decl)
    assert(meta >= 0)
    assert(pool.fn_meta_tp_count(meta) == 1)
    assert(pool.fn_meta_param_count(meta) == 1)
    let param_start = pool.fn_meta_param_start(meta)
    let param_type = pool.get_extra(param_start + 1)
    assert(pool.kind(param_type) == NodeKind.NK_TYPE_GENERIC())
    let body = pool.get_data1(decl)
    assert(pool.kind(body) == NodeKind.NK_CALL())
    assert(pool.get_data2(body) == 2)

fn test_use_path_rejects_keyword_segments:
    let src = "use std.async\nfn main -> i32:\n    0\n"
    let result = parse_module_allow_errors(src)
    assert(result.1 > 0)

fn test_c_import_requires_string_literal:
    let src = "use c_import(123)\nfn main -> i32:\n    0\n"
    let result = parse_module_allow_errors(src)
    let diag_count = result.1
    assert(diag_count > 0)

fn test_multi_error_recovery_golden:
    let src = "fn a:\n    1\nlet =\nuse\nfn b:\n    2\n"
    let result = parse_module_allow_errors(src)
    let pool = result.0
    let diag_count = result.1
    assert(diag_count >= 2)
    assert(pool.decl_count() >= 1)
    let d0 = pool.get_decl(0)
    assert(pool.kind(d0) == NodeKind.NK_FN_DECL())
    assert(pool.kind(pool.get_data1(d0)) == NodeKind.NK_INT_LIT())

fn test_c_import_malformed_syntax_matrix:
    let bad1 = parse_module_allow_errors("use c_import()\nfn main -> i32:\n    0\n")
    assert(bad1.1 > 0)

    let bad2 = parse_module_allow_errors("use c_import(123)\nfn main -> i32:\n    0\n")
    assert(bad2.1 > 0)

    let bad3 = parse_module_allow_errors("use c_import(\"h\", link)\nfn main -> i32:\n    0\n")
    assert(bad3.1 > 0)

    let bad4 = parse_module_allow_errors("use c_import(\"h\", link: 123)\nfn main -> i32:\n    0\n")
    assert(bad4.1 > 0)

    let bad5 = parse_module_allow_errors("use c_import(\"h\", link: \"x\", 123)\nfn main -> i32:\n    0\n")
    assert(bad5.1 > 0)

    let bad6 = parse_module_allow_errors("use c_import(\"h\"\nfn main -> i32:\n    0\n")
    assert(bad6.1 > 0)

fn test_chained_sugar_precedence_and_associativity:
    let pipe_src = "fn f:\n    a |> b |> c\n"
    let pipe_pool = parse_module(pipe_src)
    let pipe_decl = pipe_pool.get_decl(0)
    let pipe_body = pipe_pool.get_data1(pipe_decl)
    assert(pipe_pool.kind(pipe_body) == NodeKind.NK_PIPELINE())
    let pipe_lhs = pipe_pool.get_data0(pipe_body)
    let pipe_rhs = pipe_pool.get_data1(pipe_body)
    assert(pipe_pool.kind(pipe_rhs) == NodeKind.NK_IDENT())
    assert(pipe_pool.kind(pipe_lhs) == NodeKind.NK_PIPELINE())
    assert(pipe_pool.kind(pipe_pool.get_data0(pipe_lhs)) == NodeKind.NK_IDENT())
    assert(pipe_pool.kind(pipe_pool.get_data1(pipe_lhs)) == NodeKind.NK_IDENT())

    let compose_src = "fn g:\n    a >> b >> c\n"
    let compose_pool = parse_module(compose_src)
    let compose_decl = compose_pool.get_decl(0)
    let compose_body = compose_pool.get_data1(compose_decl)
    assert(compose_pool.kind(compose_body) == NodeKind.NK_CLOSURE())

    let rev_compose_src = "fn h:\n    a << b << c\n"
    let rev_pool = parse_module(rev_compose_src)
    let rev_decl = rev_pool.get_decl(0)
    let rev_body = rev_pool.get_data1(rev_decl)
    assert(rev_pool.kind(rev_body) == NodeKind.NK_CLOSURE())

    // ?? has higher precedence than pipeline.
    let mixed_src = "fn p:\n    a ?? b |> c\n"
    let mixed_pool = parse_module(mixed_src)
    let mixed_decl = mixed_pool.get_decl(0)
    let mixed_body = mixed_pool.get_data1(mixed_decl)
    assert(mixed_pool.kind(mixed_body) == NodeKind.NK_PIPELINE())
    assert(mixed_pool.kind(mixed_pool.get_data0(mixed_body)) == NodeKind.NK_BINARY())
    assert(mixed_pool.get_data0(mixed_pool.get_data0(mixed_body)) == BinaryOp.OP_DEFAULT)

fn test_goto_and_statement_labels:
    let goto_pool = parse_module("fn f:\n    goto 'done\n")
    let goto_body = goto_pool.get_data1(goto_pool.get_decl(0))
    assert(goto_pool.kind(goto_body) == NodeKind.NK_GOTO())

    let let_pool = parse_module("fn f:\n    'init let x = 1\n")
    let labeled_let = let_pool.get_data1(let_pool.get_decl(0))
    assert(let_pool.kind(labeled_let) == NodeKind.NK_LABEL())
    assert(let_pool.kind(let_pool.get_data1(labeled_let)) == NodeKind.NK_LET_BINDING())

    let expr_pool = parse_module("fn f:\n    'expr x + 1\n")
    let labeled_expr = expr_pool.get_data1(expr_pool.get_decl(0))
    assert(expr_pool.kind(labeled_expr) == NodeKind.NK_LABEL())
    assert(expr_pool.kind(expr_pool.get_data1(labeled_expr)) == NodeKind.NK_BINARY())

    let ret_pool = parse_module("fn f:\n    'ret return\n")
    let labeled_return = ret_pool.get_data1(ret_pool.get_decl(0))
    assert(ret_pool.kind(labeled_return) == NodeKind.NK_LABEL())
    assert(ret_pool.kind(ret_pool.get_data1(labeled_return)) == NodeKind.NK_RETURN())

    let block_pool = parse_module("fn f:\n    'block:\n        x\n")
    let labeled_block = block_pool.get_data1(block_pool.get_decl(0))
    assert(block_pool.kind(labeled_block) == NodeKind.NK_LABEL())
    assert(block_pool.kind(block_pool.get_data1(labeled_block)) == NodeKind.NK_BLOCK())

    let loop_pool = parse_module("fn f:\n    'loop while false:\n        break 'loop\n")
    let labeled_loop = loop_pool.get_data1(loop_pool.get_decl(0))
    assert(loop_pool.kind(labeled_loop) == NodeKind.NK_LABEL())
    assert(loop_pool.kind(loop_pool.get_data1(labeled_loop)) == NodeKind.NK_WHILE())

    let adjacent_pool = parse_module("fn f:\n    'a\n    'b return\n")
    let adjacent_outer = adjacent_pool.get_data1(adjacent_pool.get_decl(0))
    assert(adjacent_pool.kind(adjacent_outer) == NodeKind.NK_LABEL())
    let adjacent_inner = adjacent_pool.get_data1(adjacent_outer)
    assert(adjacent_pool.kind(adjacent_inner) == NodeKind.NK_LABEL())
    assert(adjacent_pool.kind(adjacent_pool.get_data1(adjacent_inner)) == NodeKind.NK_RETURN())

fn main:
    test_char_literal_lowering()
    test_byte_char_literal_lowering()
    test_precedence()
    test_fn_metadata()
    test_callconv_metadata_unquotes_string_literal()
    test_type_param_layout()
    test_local_let_type_annotation_storage()
    test_compose_lowering()
    test_type_expr_impl_for()
    test_type_expr_slice_alt()
    test_trait_layout_contains_assoc_and_methods()
    test_recovery_to_next_top_level_decl()
    test_trailing_commas_call_and_type_params()
    test_use_path_rejects_keyword_segments()
    test_c_import_requires_string_literal()
    test_multi_error_recovery_golden()
    test_c_import_malformed_syntax_matrix()
    test_chained_sugar_precedence_and_associativity()
    test_goto_and_statement_labels()
    print("ok")
