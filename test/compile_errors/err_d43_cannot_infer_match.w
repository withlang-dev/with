//! expect-check-fail: cannot infer return type: match arms have types i32 and Unit; add `-> i32` or `-> Unit`

// D43 / #1180: this was invalid MIR (a Unit arm stored into an i32 place).
// (#1319: an assignment arm is discarded — `true => seen = 1` is Unit, not
// i32 — so the mixed join here is spelled with a real value arm; the
// assignment-arm shape runs in behav_1319_assignment_arm_discarded.w.)

var seen: i32
fn f(p: bool):
    seen = 0
    match p:
        true => 1
        false => assert(p)

fn main: f(true)
