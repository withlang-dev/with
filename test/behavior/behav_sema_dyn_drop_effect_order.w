//! expect-stdout: ok

use pre_d_build_runner

fn assert_drop_error(forward: &P7Run, reverse: &P7Run):
    assert(forward.rc != 0)
    assert(reverse.rc == forward.rc)
    assert(forward.stderr == reverse.stderr)
    assert(forward.stderr.contains("mutates global `G` while `r` is a live view into it"))

fn main:
    let root = p7_repo_root()
    let path = "test/compile_errors/err_1827_drop_dyn_box.w"
    let forward = p7_run(root, "dyn_drop_order_forward", "check\0" ++ path ++ "\0")
    let reverse = p7_run(root, "dyn_drop_order_reverse", "check\0--sema-body-order-reverse\0" ++ path ++ "\0")
    assert_drop_error(forward, reverse)

    // A private implementor is still a possible dynamic destructor when the
    // public factory and trait cross a module boundary.
    let dir = p7_prepare_case("dyn_drop_effect_order", "droporder")
    p7_write(dir, "src/owner.w", "use std.box.Box\npub var G: List[str] = List.new()\npub trait Named:\n    fn name(self: &Self) -> i32\ntype Tok:\n    n: i32\nimpl Named for Tok:\n    fn name(self: &Self) -> i32: self.n\nimpl Drop for Tok:\n    move fn drop(): G.push(\"grown\")\npub fn make() -> Box[dyn Named]: Box.new(Tok { n: 1 })\n")
    p7_write(dir, "src/main.w", "use owner\nfn main:\n    G.push(\"first\")\n    let b = make()\n    let r = G[0]\n    {\n        let c = b\n        print(c.name())\n    }\n    print(r)\n")
    let module_forward = p7_run(dir, "dyn_drop_module_forward", "check\0src/main.w\0")
    let module_reverse = p7_run(dir, "dyn_drop_module_reverse", "check\0--sema-body-order-reverse\0src/main.w\0")
    assert_drop_error(module_forward, module_reverse)
    for reverse_order in [false, true]:
        let flags = if reverse_order: "--sema-body-order-reverse\0" else: ""
        let facts = p7_run(dir, f"dyn_drop_module_facts_{reverse_order}", "analyze\0" ++ flags ++ "src/main.w\0select:stage=sema,kind=global-effect,name=Tok\0")
        assert(facts.rc != 0)
        assert(facts.stdout.contains("drop-target"))
        assert(facts.stdout.contains("target-type=Tok"))
        assert(facts.stdout.contains("branch=enqueue-target"))
    print("ok")
