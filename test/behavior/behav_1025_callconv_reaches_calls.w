//! expect-stdout: ok

// #1025: a `@[callconv(…)]` function is declared, and called, with LLVM's
// convention of that name. `thiscall` was the number 33 (LLVM's is 70),
// `vectorcall` was fastcall's, and no call carried its callee's convention,
// which LLVM leaves undefined (`call i32 @f` against `declare
// aarch64_vector_pcs i32 @f`).
use std.fs
use std.process

fn temp_root() -> str:
    let tmpdir = env("TMPDIR")
    if tmpdir.len() > 0: return tmpdir
    let temp = env("TEMP")
    if temp.len() > 0: return temp
    "/tmp"

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let base = temp_root() ++ f"/with-behav-1025-{pid()}"
    remove_tree(base)
    assert(mkdir_p(base) == 0)
    let program = "@[callconv(\"thiscall\")]\nextern fn cc_this(x: i32) -> i32\n@[callconv(\"vectorcall\")]\nextern fn cc_vector(x: i32) -> i32\n@[callconv(\"aarch64_vfabi\")]\nextern fn cc_vfabi(x: i32) -> i32\nfn main:\n    print(unsafe { cc_this(1) + cc_vector(2) + cc_vfabi(3) })\n"
    assert(write_file(base ++ "/cc.w", program) == 0)
    let ran = run_to_files(&[compiler, "ir", base ++ "/cc.w"], base ++ "/out", base ++ "/err", 120000)
    let ir = read_file(base ++ "/out") ?? ""
    var failed = ran.code != 0
    for want in ["declare x86_thiscallcc i32 @cc_this", "call x86_thiscallcc i32 @cc_this", "declare x86_vectorcallcc i32 @cc_vector", "call x86_vectorcallcc i32 @cc_vector", "declare aarch64_vector_pcs i32 @cc_vfabi", "call aarch64_vector_pcs i32 @cc_vfabi"]:
        if not ir.contains(want):
            print(f"missing: {want}")
            failed = true
    remove_tree(base)
    if failed: print(read_file(base ++ "/err") ?? "") else: print("ok")
