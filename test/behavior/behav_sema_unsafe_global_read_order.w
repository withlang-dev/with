//! expect-stdout: ok

use pre_d_build_runner

fn compare_orders(dir: &str, label: &str) -> P7Run:
    let forward = p7_run(dir, label ++ "_forward", "check\0src/main.w\0")
    let reverse = p7_run(dir, label ++ "_reverse", "check\0--sema-body-order-reverse\0src/main.w\0")
    assert(reverse.rc == forward.rc)
    assert(reverse.stderr == forward.stderr)
    forward

fn main:
    let dir = p7_prepare_case("unsafe_global_read_order", "globalread")
    let declarations = ["let", "var", "global", "global var"]
    for ci in 0..declarations.len() as i32:
        p7_write(dir, "src/main.w", declarations[ci] ++ " number: i32 = 0\nfn mutate(): number = 1\nfn observe(): unsafe { print(number) }\nfn main: print(0)\n")
        let result = compare_orders(dir, f"unsafe_global_read_{ci}")
        assert(not result.stderr.contains("unsafe block contains no unsafe operations"))
        if ci == 0 or ci == 2:
            assert(result.rc != 0)
        else:
            p7_assert_success(result, "mutable global read")

    // A never-mutated immutable global does not make a block necessary.
    p7_write(dir, "src/main.w", "let number: i32 = 0\nfn main: unsafe { print(number) }\n")
    let unused = compare_orders(dir, "unsafe_global_read_unused")
    assert(unused.rc != 0)
    assert(unused.stderr.contains("unsafe block contains no unsafe operations"))

    // Both lexical blocks observe the same pending global-read requirement.
    p7_write(dir, "src/main.w", "let number: i32 = 0\nfn mutate(): number = 1\nfn observe(): unsafe { unsafe { print(number) } }\nfn main: print(0)\n")
    let nested = compare_orders(dir, "unsafe_global_read_nested")
    assert(nested.rc != 0)
    assert(not nested.stderr.contains("unsafe block contains no unsafe operations"))

    // A definite raw operation remains sufficient beside an immutable read.
    p7_write(dir, "src/main.w", "let number: i32 = 0\nfn main:\n    let value = 42\n    let p = &raw const value\n    unsafe { print(number + *p) }\n")
    let definite = compare_orders(dir, "unsafe_global_read_definite")
    p7_assert_success(definite, "definite raw operation")
    print("ok")
