// e2e: argument-type mismatch -> label + notes (+help when literal).
// check: out/bootstrap/bin/with-stage1 check .audit/probes/diag_render/e_arg_mismatch.w
fn take(x: i32) -> i32: x
fn main:
    take(true)
