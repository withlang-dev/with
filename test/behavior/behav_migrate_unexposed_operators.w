//! expect-stdout: ok

// #1933: an operator libclang does not name (an UnexposedExpr with several
// operands) lowered to its LAST operand: `__builtin_choose_expr(1, f(), 7)`
// was 7, `f() ?: 1` was 1 and `__atomic_load_n(&g, 0)` was 0. A discarded
// conditional arm whose lowering failed became an empty statement, so the
// call in `c ? arr[f()] : 0` vanished. Each form is now translated or
// refused by name.
use pre_d_build_runner
use std.fs

fn migrate_case(name: &str, source: &str) -> P7Run:
    let case_dir = p7_prepare_case(name, name ++ "_test")
    assert(mkdir_p(p7_join(case_dir, "lib")) == 0)
    p7_write(case_dir, "input.c", source)
    p7_run(case_dir, name ++ "_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/unexposed.w\0")

fn main:
    let ok_source = "static int calls;\nstatic int g;\nstatic int f(void) { return ++calls; }\nint choose_first(void) { return __builtin_choose_expr(1, f(), 7); }\nint choose_second(void) { return __builtin_choose_expr(0, f(), 7); }\nint elvis_fallback(void) { return g ?: f(); }\nint elvis_once(void) { return f() ?: 99; }\nint arm_calls(int c) { int arr[4] = { 0 }; c ? arr[f() & 3] : 0; return calls; }\nint call_count(void) { return calls; }\n"
    let case_dir = p7_prepare_case("migrate_unexposed_operators", "unexposed_operators_test")
    assert(mkdir_p(p7_join(case_dir, "lib")) == 0)
    p7_write(case_dir, "input.c", ok_source)
    let migrated = p7_run(case_dir, "unexposed_operators_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/unexposed.w\0")
    p7_assert_success(migrated, "migrate choose_expr, a ?: b and a discarded conditional arm")
    p7_write(case_dir, "src/main.w", "use unexposed\nfn main:\n    assert(choose_first() == 1)\n    assert(choose_second() == 7)\n    assert(call_count() == 1)\n    assert(elvis_fallback() == 2)\n    assert(elvis_once() == 3)\n    assert(call_count() == 3)\n    assert(arm_calls(1) == 4)\n    assert(arm_calls(0) == 4)\n    print(\"unexposed ok\")\n")
    let executed = p7_run(case_dir, "unexposed_operators_run", "run\0src/main.w\0")
    p7_assert_success(executed, "run the selected operand, the single evaluation and the arm's call")
    assert(executed.stdout.contains("unexposed ok"))

    let atomic = migrate_case("migrate_unexposed_atomic", "static int g;\nint load(void) { return __atomic_load_n(&g, 0); }\n")
    p7_assert_failure_contains(atomic, "has no translation", "an atomic builtin is refused by name, not read as its last operand")

    let refused_arm = migrate_case("migrate_refused_arm", "union U { int a; long b; };\nvoid t(int c) { int arr[4] = { 0 }; c ? arr[(union U){ .a = 1, .b = 2 }.a] : 0; }\n")
    p7_assert_failure_contains(refused_arm, "union initializer sets multiple arms", "a discarded arm whose lowering fails fails the function")
    print("ok")
