//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let root = p7_repo_root()
    let path = "test/compile_errors/err_sema_downcast_name_lifetime.w"
    let forward = p7_run(root, "downcast_name_lifetime_forward", "check\0" ++ path ++ "\0")
    let reverse = p7_run(root, "downcast_name_lifetime_reverse", "check\0--sema-body-order-reverse\0" ++ path ++ "\0")
    assert(forward.rc != 0)
    assert(reverse.rc == forward.rc)
    assert(forward.stderr == reverse.stderr)
    assert(forward.stderr.contains("cannot assign through a read-only place"))
    assert(not forward.stderr.contains("downcast pattern matched"))

    // A live downcast binding still receives the specialized help.
    let live = p7_run(root, "downcast_name_lifetime_live", "check\0test/compile_errors/err_1860_dyn_downcast_assign_help.w\0")
    assert(live.rc != 0)
    assert(live.stderr.contains("downcast pattern matched"))
    print("ok")
