//! expect-stdout: ok

use pre_d_build_runner

// #1590: the single-thread-proof advice about an `unsafe` global access is
// located at the access, in the module that holds it. The deferred pass ran
// after every body and read the span in whatever file was current last —
// the root module (or a rendered `<facade …>` file) at a line that does not
// exist.
fn main:
    let case_dir = p7_prepare_case("global_race_warning_located", "racewarn")
    p7_write(case_dir, "counter.w", "global var counter: i32 = 0
pub fn bump():
    unsafe { counter = counter + 1 }
")
    p7_write(case_dir, "main.w", "use counter
fn main:
    bump()
    print(\"ok\")
")
    let checked = p7_run(case_dir, "global-race-warning-located", "check\0main.w\0")
    p7_assert_success(checked, "with check")
    assert(checked.stderr.contains("warning: unsafe global access is currently covered by the single-thread proof"))
    assert(checked.stderr.contains("--> counter.w:3:"))
    assert(not checked.stderr.contains("--> main.w"))
    print("ok")
