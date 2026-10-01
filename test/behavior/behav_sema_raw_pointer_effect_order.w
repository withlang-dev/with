//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let dir = p7_prepare_case("raw_pointer_effect_order", "raworder")
    let leaf = "unsafe fn read_first(p: *const i32) -> i32:\n    *p\n"
    let cases = [
        leaf ++ "fn wrapper(p: *const i32) -> i32:\n    unsafe { read_first(p) }\n",
        leaf ++ "fn middle(p: *const i32) -> i32:\n    unsafe { read_first(p) }\nfn wrapper(p: *const i32) -> i32:\n    middle(p)\n",
        "unsafe fn read_first(p: &*const i32) -> i32:\n    **p\nfn wrapper(p: &*const i32) -> i32:\n    unsafe { read_first(p) }\n",
        leaf ++ "fn wrapper(p: *const i32) -> i32:\n    let q = p\n    unsafe { read_first(q) }\n",
        leaf ++ "fn wrapper(p: *const i32) -> i32:\n    let q: *const i32 = p\n    unsafe { read_first(q) }\n",
    ]
    for ci in 0..cases.len() as i32:
        p7_write(dir, "src/main.w", cases[ci] ++ "fn main: print(0)\n")
        let forward = p7_run(dir, f"raw_order_{ci}_forward", "check\0src/main.w\0")
        let reverse = p7_run(dir, f"raw_order_{ci}_reverse", "check\0--sema-body-order-reverse\0src/main.w\0")
        assert(forward.rc != 0)
        assert(reverse.rc == forward.rc)
        assert(forward.stderr == reverse.stderr)
        assert(forward.stderr.contains("safe function relies on caller-guaranteed raw pointer validity"))
        assert(forward.stderr.contains("fn wrapper("))
        for reverse_order in [false, true]:
            let flags = if reverse_order: "--sema-body-order-reverse\0" else: ""
            let facts = p7_run(dir, f"raw_order_facts_{ci}_{reverse_order}", "analyze\0src/main.w\0select:stage=sema,kind=parameter,name=wrapper\0" ++ flags)
            assert(facts.rc != 0)
            assert(facts.stdout.contains("owned direct=1 final=32") or facts.stdout.contains("borrowed direct=1 final=32"))
    // Pointer transport alone has no validity precondition.
    p7_write(dir, "src/main.w", "fn identity(p: *const i32) -> *const i32: p\nfn wrapper(p: *const i32) -> *const i32: identity(p)\nfn main: print(0)\n")
    for reverse in [false, true]:
        let flags = if reverse: "--sema-body-order-reverse\0" else: ""
        let result = p7_run(dir, f"raw_order_identity_{reverse}", "check\0" ++ flags ++ "src/main.w\0")
        assert(result.rc == 0)
    print("ok")
