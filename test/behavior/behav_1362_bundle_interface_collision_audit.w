//! expect-stdout: ok

// #1362: analyze audit:all over programs whose own fns are named like bundle
// interface fns. The interface declaration used to share the user fn's flat
// symbol, so the codegen audit checked the interface signature against the
// user's function ("finalized source type or LLVM parameter disagrees with
// FnAbi") and codegen failed. `collide` pulls std.re and std.zl (the
// behavior fixture itself, audited clean); `corpora` pulls std.c_algorithms
// (SortedVec) and std.tommyds (hash_index) as well. `corpora` still carries
// the "receiver requirement" violation every program reaching std.box
// reports (#1300), so it asserts only that no FnAbi or codegen violation
// names a declaration.
use std.fs
use pre_d_build_runner

fn helpers_text -> str:
    "fn is_alpha(ch: u8) -> bool: ch == 1\n" ++
        "fn is_digit(ch: u8) -> bool: ch == 2\n" ++
        "fn is_alnum(ch: u8) -> bool: ch == 4\n" ++
        "fn to_lower(ch: u8) -> u8: ch + 1\n" ++
        "fn __ci_unreachable() -> i32: 11\n" ++
        "fn u128_mul_would_overflow(a: i32, b: i32) -> i32: a * b\n"

fn main:
    let case_dir = p7_prepare_case("bundle_interface_collision", "bundle_interface_collision")
    let collide = read_file(p7_abs("test/behavior/behav_1362_user_fns_named_like_bundle_interface_fns.w")).unwrap()
    p7_write(case_dir, "src/collide.w", collide)
    let audited = p7_run(case_dir, "collide_audit", "analyze\0src/collide.w\0audit:all\0")
    p7_assert_success(audited, "audit:all over user fns named like std.re/std.zl interface fns")
    assert(audited.stdout.contains("violations=0"))

    let corpora = "use std.collections.sorted_vec.SortedVec\nuse std.collections.hash_index\n" ++ helpers_text() ++
        "fn main:\n" ++
        "    assert(is_alpha(1) and is_digit(2) and is_alnum(4) and to_lower(1) == 2)\n" ++
        "    assert(u128_mul_would_overflow(6, 7) == 42 and __ci_unreachable() == 11)\n" ++
        "    var s: SortedVec[i32] = SortedVec.new()\n" ++
        "    s.insert(3)\n" ++
        "    s.insert(1)\n" ++
        "    assert(s.len() == 2)\n" ++
        "    print(\"corpora ok\")\n"
    p7_write(case_dir, "src/corpora.w", corpora)
    let ran = p7_run(case_dir, "corpora_run", "run\0src/corpora.w\0")
    p7_assert_success(ran, "user fns named like std.c_algorithms/std.tommyds interface fns")
    assert(ran.stdout.contains("corpora ok"))
    let corpora_audit = p7_run(case_dir, "corpora_audit", "analyze\0src/corpora.w\0audit:all\0")
    let report = corpora_audit.stdout ++ corpora_audit.stderr
    assert(not report.contains("FnAbi"))
    assert(not report.contains("code generation failed"))
    print("ok")
