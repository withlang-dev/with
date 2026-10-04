//! skip-on: windows issue #802: core-language behavior fails on native Windows (needs root-cause)
//! expect-stdout: ok

// #2073: a MIR call that is all intrinsic names no function: its callee
// operand is the Unit placeholder. Where the C backend has no lowering for
// the intrinsic it resolved the placeholder as if it were a callee — an
// unrelated function in the prelude (`_4 = StringBuilder_new__41();` for the
// #1985 cancelled-return check), "cannot resolve call callee" here. It now
// names the intrinsic and the function that calls it.

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("emit_c_unlowered_intrinsic", "emitcunlowered")
    p7_write(case_dir, "src/main.w", "async fn work() -> i32: 7\nfn main:\n    let t = work()\n    print(f\"{t.await}\")\n")
    let run = p7_run(case_dir, "emit-c of an await", "build\0src/main.w\0--emit-c\0-o\0out/main.c\0")
    assert(run.rc != 0)
    if not run.stderr.contains("C backend has no lowering for MIR intrinsic") or not run.stderr.contains("called in `main`"):
        eprint(run.stderr)
        assert(false)
    print("ok")
