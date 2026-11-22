//! expect-stdout: ok

// Effect-seed refinement (#919 chase): `&raw mut self.field` inside a
// `mut fn` does NOT demand `move fn`. A mut receiver is a compiler-
// modeled BORROWED place (IndirectPlace) — the caller retains ownership
// and its drop, so the raw-pointer smuggle rationale (Box.new's
// caller-must-transfer) cannot apply. Pins StringBuilder.push_str's
// shape end to end; the consuming-param seed stays (behav_box_drop).
use std.string.StringBuilder

fn main:
    var sb = StringBuilder.new()
    sb.push_str("a")
    sb.push_str("b")
    let s = sb.to_str()
    assert(s == "ab")
    var sb2 = StringBuilder.with_capacity(1024)
    var i = 0
    while i < 1000:
        sb2.push_str("xy")
        i = i + 1
    assert(sb2.len() == 2000)
    print("ok")
