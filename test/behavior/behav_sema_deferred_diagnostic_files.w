//! expect-stdout: ok

use pre_d_build_runner

// Deferred semantic judgments retain the parser's file for every node,
// including a generator's yield and a pull in a different module.
fn assert_same_error(forward: &P7Run, reverse: &P7Run):
    assert(forward.rc != 0)
    assert(reverse.rc == forward.rc)
    assert(forward.stderr == reverse.stderr)
    assert(not forward.stderr.contains("<embedded-std>"))

fn main:
    let root = p7_repo_root()
    for name in ["err_d21_mut_receiver_owned_escape", "err_receiver_contract_mut_escape", "err_d60_self_receiver_tail", "err_gen_pull_may_suspend", "err_gen_pull_view_of_own_local"]:
        let path = "test/compile_errors/" ++ name ++ ".w"
        let forward = p7_run(root, name ++ "_forward", "check\0" ++ path ++ "\0")
        let reverse = p7_run(root, name ++ "_reverse", "check\0--sema-body-order-reverse\0" ++ path ++ "\0")
        assert_same_error(forward, reverse)
        assert(forward.stderr.contains(path))

    let dir = p7_prepare_case("deferred_diagnostic_files", "diagfiles")
    p7_write(dir, "src/producer.w", "pub gen fn labels() -> &str:\n    var text = \"label\"\n    yield &text\n")
    p7_write(dir, "src/main.w", "use producer\nfn main:\n    var steps = labels().pull()\n    print(steps.next().unwrap())\n")
    let forward = p7_run(dir, "cross_file_pull_forward", "check\0src/main.w\0")
    let reverse = p7_run(dir, "cross_file_pull_reverse", "check\0--sema-body-order-reverse\0src/main.w\0")
    assert_same_error(forward, reverse)
    assert(forward.stderr.contains("src/producer.w:3:"))
    assert(forward.stderr.contains("label src/main.w@3:"))
    assert(forward.stderr.contains("pulled here"))
    print("ok")
