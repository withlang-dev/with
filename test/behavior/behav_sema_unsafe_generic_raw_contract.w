//! expect-stdout: ok

use pre_d_build_runner

// A generic specialization keeps its source declaration's unsafe contract.
// Safe wrappers still inherit the pointer validity requirement through it.
fn main:
    let dir = p7_prepare_case("unsafe_generic_raw_contract", "unsafecontract")
    let leaf = "unsafe fn load[T](p: *const T) -> T: *p\n"
    let safe_use = leaf ++ "fn main:\n    let value = 42\n    let p = &raw const value\n    print(unsafe { load(p) })\n"
    p7_write(dir, "src/main.w", safe_use)
    for reverse_order in [false, true]:
        let flags = if reverse_order: "--sema-body-order-reverse\0" else: ""
        let result = p7_run(dir, f"unsafe_generic_raw_{reverse_order}", "run\0" ++ flags ++ "src/main.w\0")
        assert(result.rc == 0)
        assert(result.stdout == "42\n")
        let facts = p7_run(dir, f"unsafe_generic_raw_facts_{reverse_order}", "analyze\0" ++ flags ++ "src/main.w\0select:stage=sema,kind=signature,name~load__sema__\0")
        assert(facts.rc == 0)
        assert(facts.stdout.contains("declared-unsafe=1"))

    p7_write(dir, "src/main.w", leaf ++ "fn wrapper(p: *const i32) -> i32: unsafe { load(p) }\nfn main: print(0)\n")
    let forward = p7_run(dir, "unsafe_generic_wrapper_forward", "check\0src/main.w\0")
    let reverse = p7_run(dir, "unsafe_generic_wrapper_reverse", "check\0--sema-body-order-reverse\0src/main.w\0")
    assert(forward.rc != 0)
    assert(forward.stderr == reverse.stderr)
    assert(forward.stderr.contains("fn wrapper("))
    assert(not forward.stderr.contains("unsafe fn load"))
    print("ok")
