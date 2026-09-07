// e2e: candidate multi-line span (if-join mismatch across lines).
// check: out/bootstrap/bin/with-stage1 check .audit/probes/diag_render/e_multiline.w
fn f() -> i32:
    if true:
        1
    else:
        "s"
fn main:
    f()
