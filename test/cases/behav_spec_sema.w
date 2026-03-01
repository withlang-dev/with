//! expect-stdout: ok

// Spec conformance: semantics/type-system behavior
// Tracks docs/missing_features2.md section 4 (items 28-37)

use spec_harness

fn test_28_impl_method_semantics() -> i32:
    let src = "type Counter = struct value: i32\nimpl Counter\n    fn inc(self) -> Counter:\n        Counter { value: self.value + 1 }\nfn main:\n    let c = Counter { value: 1 }\n    let d = c.inc()\n    assert(d.value == 2)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_sema_28_impl", src)
    expect_eq_i32(rc, CR_OK(), "28 impl methods are fully semantic")

fn test_29_trait_method_semantics() -> i32:
    let src = "trait AddOne =\n    fn add_one(self) -> i32\ntype Boxed = struct value: i32\nimpl AddOne for Boxed\n    fn add_one(self) -> i32:\n        self.value + 1\nfn call_add_one[T](x: T) -> i32:\n    x.add_one()\nfn main:\n    let b = Boxed { value: 41 }\n    assert(call_add_one(b) == 42)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_sema_29_trait", src)
    expect_eq_i32(rc, CR_OK(), "29 trait semantics include method metadata/dispatch")

fn test_30_generic_type_resolution() -> i32:
    let src = "type Box[T] = struct value: T\nfn main:\n    let b = Box[i32] { value: 7 }\n    assert(b.value == 7)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_sema_30_generics", src)
    expect_eq_i32(rc, CR_OK(), "30 generic type resolution")

fn test_31_with_binding_semantics() -> i32:
    let src = "fn main:\n    let s = \"abc\"\n    with s as v:\n        assert(v.len() == 3)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_sema_31_with", src)
    expect_eq_i32(rc, CR_OK(), "31 with binding/body semantics")

fn test_32_for_binding_semantics() -> i32:
    let src = "fn main:\n    var sum = 0\n    for n in [1, 2, 3]:\n        sum = sum + n\n    assert(sum == 6)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_sema_32_for", src)
    expect_eq_i32(rc, CR_OK(), "32 for binding/iter/body semantics")

fn test_33_match_exhaustiveness() -> i32:
    let src = "fn main:\n    let b = true\n    let x = match b:\n        true => 1\n    println_i64(x as i64)\n"
    let rc = run_check_case("spec_sema_33_exhaustive", src)
    expect_eq_i32(rc, CR_SEMA_ERROR(), "33 non-exhaustive match is rejected")

fn test_34_implicit_ok_and_default_return() -> i32:
    var failures = 0
    let ok_wrap = "fn parse() -> Result[i32, i32]:\n    7\nfn main:\n    assert(parse().unwrap_or(0) == 7)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_sema_34_ok_wrap", ok_wrap), CR_OK(), "34 implicit Ok wrapping")

    let default_return = "fn f() -> i32:\n    if false:\n        return 1\nfn main:\n    assert(f() == 0)\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_run_case("spec_sema_34_default_return", default_return), CR_OK(), "34 implicit default return insertion")
    failures

fn test_35_auto_ref_deref_and_object_coercion() -> i32:
    let src = "type Counter = struct value: i32\nimpl Counter\n    fn get(self) -> i32:\n        self.value\nfn takes_ref(x: &Counter) -> i32:\n    x.get()\nfn main:\n    let c = Counter { value: 9 }\n    assert(takes_ref(c) == 9)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_sema_35_autoref", src)
    expect_eq_i32(rc, CR_OK(), "35 auto-ref/auto-deref/object coercions")

fn test_36_move_borrow_guarantees_in_pipeline() -> i32:
    let src = "fn consume(s: str) -> i32:\n    s.len()\nfn main:\n    let s = \"abc\"\n    let a = consume(s)\n    let b = consume(s)\n    println_i64((a + b) as i64)\n"
    let rc = run_check_case("spec_sema_36_move", src)
    expect_true(rc == CR_SEMA_ERROR() or rc == CR_BORROW_ERROR(), "36 move/borrow guarantees enforced in check/build/run")

fn test_37_lints_and_denies() -> i32:
    var failures = 0

    let must_use = "@[must_use]\nfn f() -> i32:\n    1\nfn main:\n    f()\n    println(\"ok\")\n"
    failures = failures + expect_eq_i32(run_check_case("spec_sema_37_must_use", must_use), CR_SEMA_ERROR(), "37 must_use lint")

    let unreachable = "fn main:\n    return\n    let x = 1\n    println_i64(x as i64)\n"
    failures = failures + expect_eq_i32(run_check_case("spec_sema_37_unreachable", unreachable), CR_SEMA_ERROR(), "37 unreachable-code lint")

    let unnecessary_unsafe = "fn main:\n    unsafe:\n        let x = 1\n    println_i64(x as i64)\n"
    failures = failures + expect_eq_i32(run_check_case("spec_sema_37_unnecessary_unsafe", unnecessary_unsafe), CR_SEMA_ERROR(), "37 unnecessary-unsafe lint")

    let narrowing = "fn main:\n    let x: i8 = 1000\n    println_i64(x as i64)\n"
    failures = failures + expect_eq_i32(run_check_case("spec_sema_37_narrowing", narrowing), CR_SEMA_ERROR(), "37 narrowing diagnostics")

    failures

fn main:
    var failures = 0
    failures = failures + test_28_impl_method_semantics()
    failures = failures + test_29_trait_method_semantics()
    failures = failures + test_30_generic_type_resolution()
    failures = failures + test_31_with_binding_semantics()
    failures = failures + test_32_for_binding_semantics()
    failures = failures + test_33_match_exhaustiveness()
    failures = failures + test_34_implicit_ok_and_default_return()
    failures = failures + test_35_auto_ref_deref_and_object_coercion()
    failures = failures + test_36_move_borrow_guarantees_in_pipeline()
    failures = failures + test_37_lints_and_denies()
    finalize_failures(failures)
