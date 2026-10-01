//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let root = p7_repo_root()
    let path = "test/compile_errors/err_thread_spawn_closure_captures_ref.w"
    let forward = p7_run(root, "closure_order_thread_forward", "check\0" ++ path ++ "\0")
    let reverse = p7_run(root, "closure_order_thread_reverse", "check\0--sema-body-order-reverse\0" ++ path ++ "\0")
    assert(forward.rc != 0)
    assert(reverse.rc == forward.rc)
    assert(forward.stderr == reverse.stderr)
    assert(forward.stderr.contains("escaping closure cannot capture ephemeral references"))
    assert(forward.stderr.contains("non-Send value `r`"))
    assert(forward.stderr.contains("stores or returns its parameter"))

    let dir = p7_prepare_case("closure_escape_order", "closureorder")
    p7_write(dir, "src/main.w", "fn keep(f: fn() -> i32) -> fn() -> i32: f\nfn main:\n    let x = 42\n    let r = &x\n    let kept = keep(() => *r)\n    print(kept())\n")
    let kept_forward = p7_run(dir, "closure_order_keep_forward", "check\0src/main.w\0")
    let kept_reverse = p7_run(dir, "closure_order_keep_reverse", "check\0--sema-body-order-reverse\0src/main.w\0")
    assert(kept_forward.rc != 0)
    assert(kept_forward.stderr == kept_reverse.stderr)
    assert(kept_reverse.stderr.contains("escaping closure cannot capture ephemeral references"))
    let facts = p7_run(dir, "closure_order_keep_facts", "analyze\0src/main.w\0select:stage=sema,kind=expression,detail~closure\0--sema-body-order-reverse\0")
    assert(facts.rc != 0)
    assert(facts.stdout.contains("non-escaping=0"))
    assert(facts.stdout.contains("ephemeral=1"))
    assert(facts.stdout.contains("callee=keep"))

    // A synchronous observer may use a reference capture within this frame.
    p7_write(dir, "src/main.w", "fn invoke(f: fn() -> i32) -> i32: f()\nfn main:\n    let x = 42\n    let r = &x\n    print(invoke(() => *r))\n")
    for reverse_order in [false, true]:
        let flags = if reverse_order: "--sema-body-order-reverse\0" else: ""
        let result = p7_run(dir, f"closure_order_invoke_{reverse_order}", "run\0" ++ flags ++ "src/main.w\0")
        assert(result.rc == 0)
        assert(result.stdout == "42\n")
    print("ok")
