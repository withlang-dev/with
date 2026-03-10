//! expect-stdout: ok

// Spec conformance: lowering/codegen behavior
// Tracks docs/missing_features2.md section 3 (items 21-27)

use spec_harness

fn test_21_node_kinds_lower_to_c() -> i32:
    var failures = 0

    let optional_chain = "fn main:\n    let s: ?str = \"abcd\"\n    let n = s?.len()\n    assert(n == 4)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_codegen_21_optional_chain", optional_chain), CR_OK, "21 optional chain lowers")

    let async_spawn_await = "async fn one() -> i32:\n    1\nfn main:\n    let t = spawn one()\n    let v = await t\n    assert(v == 1)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_codegen_21_async_spawn_await", async_spawn_await), CR_OK, "21 await/spawn lower")

    let yield_prog = "gen fn counter() -> i32:\n    yield 1\n    yield 2\n    3\nfn main:\n    let c = counter()\n    assert(c.next().unwrap() == 1)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_codegen_21_yield", yield_prog), CR_OK, "21 yield lowers")

    let comptime_prog = "fn main:\n    let x = comptime 1 + 2\n    assert(x == 3)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_codegen_21_comptime", comptime_prog), CR_OK, "21 comptime expr lowers")

    let with_prog = "fn main:\n    let s = \"abc\"\n    with s as v:\n        assert(v.len() == 3)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_codegen_21_with", with_prog), CR_OK, "21 with expression lowers")

    let record_update = "type P = struct x: i32\n    y: i32\nfn main:\n    let p1 = P { x: 1, y: 2 }\n    let p2 = { p1 with y: 9 }\n    assert(p2.x == 1)\n    assert(p2.y == 9)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_codegen_21_record_update", record_update), CR_OK, "21 record update lowers")

    let match_prog = "fn main:\n    let x = 2\n    let y = match x:\n        1 => 10\n        2 => 20\n        _ => 0\n    assert(y == 20)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_codegen_21_match", match_prog), CR_OK, "21 match lowers")

    let range_prog = "fn main:\n    let r = 0..3\n    assert(r.start == 0)\n    assert(r.end == 3)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_codegen_21_range", range_prog), CR_OK, "21 range lowers")

    let pipeline_prog = "fn inc(x: i32) -> i32:\n    x + 1\nfn main:\n    let y = 1 |> inc\n    assert(y == 2)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_codegen_21_pipeline", pipeline_prog), CR_OK, "21 pipeline lowers")

    let slice_prog = "fn main:\n    let a = [1, 2, 3, 4]\n    let s = a[1..3]\n    assert(s[0] == 2)\n    assert(s[1] == 3)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_codegen_21_slice", slice_prog), CR_OK, "21 slice lowers")

    let closure_prog = "fn main:\n    let f = |x: i32| x + 1\n    assert(f(2) == 3)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_codegen_21_closure", closure_prog), CR_OK, "21 closure lowers")

    let variant_shorthand = "type Opt = enum Some(i32) None\nfn main:\n    let x: Opt = .Some(3)\n    let y = match x:\n        .Some(v) => v\n        .None => 0\n    assert(y == 3)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_codegen_21_variant_shorthand", variant_shorthand), CR_OK, "21 variant shorthand lowers")

    let tuple_destructure = "fn main:\n    let (a, b) = (2, 5)\n    assert(a + b == 7)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_codegen_21_tuple_destructure", tuple_destructure), CR_OK, "21 tuple destructure lowers")

    failures

fn test_22_default_operator_semantics() -> i32:
    let src = "fn main:\n    let a: ?i32 = none\n    let b = a ?? 9\n    assert(b == 9)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_codegen_22_default_op", src)
    expect_eq_i32(rc, CR_OK, "22 ?? lowers with correct semantics")

fn test_23_try_operator_semantics() -> i32:
    let src = "fn parse(x: i32) -> Result[i32, i32]:\n    Ok(x)\nfn f() -> Result[i32, i32]:\n    let v = parse(3)?\n    Ok(v + 1)\nfn main:\n    assert(f().unwrap_or(0) == 4)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_codegen_23_try_op", src)
    expect_eq_i32(rc, CR_OK, "23 try operator lowers")

fn test_24_defer_scope_exit() -> i32:
    let src = "fn f() -> i32:\n    var x = 1\n    defer x = x + 1\n    x\nfn main:\n    assert(f() == 2)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_codegen_24_defer", src)
    expect_eq_i32(rc, CR_OK, "24 defer runs on scope exit")

fn test_25_wrapping_arithmetic() -> i32:
    let src = "fn main:\n    let x: u8 = 255\n    let y: u8 = x +% 1\n    let z: u8 = 0 -% 1\n    assert(y == 0)\n    assert(z == 255)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_codegen_25_wrap_arith", src)
    expect_eq_i32(rc, CR_OK, "25 wrapping arithmetic semantics")

fn test_26_function_composition_ops() -> i32:
    let src = "fn inc(x: i32) -> i32:\n    x + 1\nfn dbl(x: i32) -> i32:\n    x * 2\nfn main:\n    let f = inc >> dbl\n    let g = dbl << inc\n    assert(f(2) == 6)\n    assert(g(2) == 6)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_codegen_26_fn_compose", src)
    expect_eq_i32(rc, CR_OK, "26 function composition operators")

fn test_27_struct_field_defaults() -> i32:
    let src = "type P = struct x: i32\n    y: i32 = 10\nfn main:\n    let p = P { x: 2 }\n    assert(p.x == 2)\n    assert(p.y == 10)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_codegen_27_struct_defaults", src)
    expect_eq_i32(rc, CR_OK, "27 struct default field insertion")

fn main:
    var failures = 0
    failures = failures + test_21_node_kinds_lower_to_c()
    failures = failures + test_22_default_operator_semantics()
    failures = failures + test_23_try_operator_semantics()
    failures = failures + test_24_defer_scope_exit()
    failures = failures + test_25_wrapping_arithmetic()
    failures = failures + test_26_function_composition_ops()
    failures = failures + test_27_struct_field_defaults()
    finalize_failures(failures)
