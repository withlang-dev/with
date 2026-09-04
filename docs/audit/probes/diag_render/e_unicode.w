// e2e: CJK bytes precede the error span on its line -> byte-col caret.
// check: out/bootstrap/bin/with-stage1 check .audit/probes/diag_render/e_unicode.w
fn take(x: i32) -> i32: x
fn main:
    let a = "中文"; take("zz")
