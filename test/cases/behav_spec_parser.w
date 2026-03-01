//! expect-stdout: ok

// Spec conformance: parser/syntax behavior
// Tracks docs/missing_features2.md section 2 (items 6-20)

use spec_harness
use Token
use Lexer
use Parser
use Ast

fn test_06_string_interpolation() -> i32:
    let src = "fn main:\n    let name = \"world\"\n    let s = \"hello {name}\"\n    assert(s == \"hello world\")\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_06_string_interpolation", src)
    expect_eq_i32(rc, CR_OK(), "06 string interpolation")

fn test_07_if_let_let_else_chained() -> i32:
    let src = "type Opt = enum Some(i32) None\nfn get(x: Opt) -> i32:\n    if let Opt.Some(v) = x:\n        v\n    else:\n        0\nfn main:\n    let a = Opt.Some(7)\n    assert(get(a) == 7)\n    if let Opt.Some(v1) = a:\n        assert(v1 == 7)\n    else if let Opt.None = a:\n        assert(false)\n    else:\n        assert(false)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_07_if_let", src)
    expect_eq_i32(rc, CR_OK(), "07 if-let / let-else / chained if-let")

fn test_08_list_comprehension() -> i32:
    let src = "fn main:\n    let xs = [1, 2, 3]\n    let ys = [x * 2 for x in xs]\n    assert(ys[0] == 2)\n    assert(ys[1] == 4)\n    assert(ys[2] == 6)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_08_list_comp", src)
    expect_eq_i32(rc, CR_OK(), "08 list comprehensions")

fn test_09_default_params() -> i32:
    let src = "fn add(a: i32, b: i32 = 10) -> i32:\n    a + b\nfn main:\n    assert(add(5) == 15)\n    assert(add(5, 2) == 7)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_09_default_params", src)
    expect_eq_i32(rc, CR_OK(), "09 default function parameters")

fn test_10_placeholder_closure_and_partial_app() -> i32:
    let src = "fn add(a: i32, b: i32) -> i32:\n    a + b\nfn main:\n    let plus2 = add(_, 2)\n    assert(plus2(3) == 5)\n    let slen = _.len()\n    assert(slen(\"abcd\") == 4)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_10_placeholder_partial", src)
    expect_eq_i32(rc, CR_OK(), "10 placeholder closure + partial application")

fn test_11_advanced_match_patterns() -> i32:
    let src = "type Pair = struct x: i32\n    y: i32\nfn main:\n    let p = Pair { x: 2, y: 9 }\n    let a = [1, 2, 3, 4]\n    let n = 2\n    let score = match n:\n        0 | 1 => 1\n        v @ 2..=3 => v\n        _ => 0\n    assert(score == 2)\n    let score2 = match p:\n        Pair { x, y } => x + y\n    assert(score2 == 11)\n    let score3 = match a:\n        [head, ..rest] => head + rest[0]\n    assert(score3 == 3)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_11_patterns", src)
    expect_eq_i32(rc, CR_OK(), "11 advanced match patterns")

fn test_12_fn_param_pattern_destructure() -> i32:
    let src = "fn sum_pair((a, b): (i32, i32)) -> i32:\n    a + b\nfn main:\n    assert(sum_pair((2, 3)) == 5)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_12_param_destructure", src)
    expect_eq_i32(rc, CR_OK(), "12 fn parameter pattern destructuring")

fn test_13_for_destructure() -> i32:
    let src = "fn main:\n    let pairs = [(1, 2), (3, 4)]\n    var sum = 0\n    for (a, b) in pairs:\n        sum = sum + a + b\n    assert(sum == 10)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_13_for_destructure", src)
    expect_eq_i32(rc, CR_OK(), "13 for destructuring")

fn test_14_error_declarations() -> i32:
    let src = "error IoError\nerror ParseError\nfn main:\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_14_error_decl", src)
    expect_eq_i32(rc, CR_OK(), "14 error declarations")

fn test_15_error_from_conversion() -> i32:
    let src = "error IoError\nerror ParseError from IoError\nfn main:\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_15_error_from", src)
    expect_eq_i32(rc, CR_OK(), "15 error-from conversion syntax")

fn test_16_select_await() -> i32:
    let src = "async fn left() -> i32:\n    1\nasync fn right() -> i32:\n    2\nfn main:\n    let out = select await:\n        v = left() => v\n        v = right() => v\n    assert(out == 1 or out == 2)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_16_select_await", src)
    expect_eq_i32(rc, CR_OK(), "16 select await")

fn test_17_async_scope_forms() -> i32:
    let src = "fn main:\n    let a = async:\n        1 + 1\n    let b = async scope:\n        3\n    let c = scope |s|:\n        4\n    assert(a == 2)\n    assert(b == 3)\n    assert(c == 4)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_17_async_scope", src)
    expect_eq_i32(rc, CR_OK(), "17 async:block / async scope / scope |s|")

fn test_18_multi_with_bindings() -> i32:
    let src = "fn main:\n    with \"abc\" as a, \"xyz\" as b:\n        assert(a.len() == 3)\n        assert(b.len() == 3)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_18_multi_with", src)
    expect_eq_i32(rc, CR_OK(), "18 multiple with bindings")

fn test_19_comptime_if_for() -> i32:
    let src = "fn main:\n    let x = comptime if true then 1 else 2\n    var sum = 0\n    comptime for i in 0..3:\n        sum = sum + i\n    assert(x == 1)\n    assert(sum == 3)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_parser_19_comptime_if_for", src)
    expect_eq_i32(rc, CR_OK(), "19 comptime if / comptime for")

fn test_20_attributes_attached_to_semantic_model() -> i32:
    let src = "@[must_use]\nfn f() -> i32:\n    1\n"
    var l = Lexer.new(src, 0)
    var tokens = Lexer.tokenize(l)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    if AstPool.decl_count(p.pool) < 1:
        return expect_true(false, "20 attributes parsed and attached (no decls)")
    let decl = AstPool.get_decl(p.pool, 0)
    let extra_start = AstPool.get_data2(p.pool, decl)
    let flags = AstPool.get_extra(p.pool, extra_start + 1)
    let has_must_use = ((flags / 32) % 2) == 1
    expect_true(has_must_use, "20 attributes attached to fn metadata")

fn main:
    var failures = 0
    failures = failures + test_06_string_interpolation()
    failures = failures + test_07_if_let_let_else_chained()
    failures = failures + test_08_list_comprehension()
    failures = failures + test_09_default_params()
    failures = failures + test_10_placeholder_closure_and_partial_app()
    failures = failures + test_11_advanced_match_patterns()
    failures = failures + test_12_fn_param_pattern_destructure()
    failures = failures + test_13_for_destructure()
    failures = failures + test_14_error_declarations()
    failures = failures + test_15_error_from_conversion()
    failures = failures + test_16_select_await()
    failures = failures + test_17_async_scope_forms()
    failures = failures + test_18_multi_with_bindings()
    failures = failures + test_19_comptime_if_for()
    failures = failures + test_20_attributes_attached_to_semantic_model()
    finalize_failures(failures)
