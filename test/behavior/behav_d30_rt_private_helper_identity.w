//! check-only

// D30 ruling 4 (§18.2, D70): the in-unit runtime's modules bind by their
// own scope. A user function named like a runtime private helper is the
// user's; it never captures the runtime's own calls (rt_core.w's
// `make_str(out, len)` bound to this program's `make_str()` and refused
// the arguments), and the runtime helper never leaks into the program.
use std.builtins.print

// `make_str` is private in rt_core.w and public in fiber_runtime.w,
// `str_data` likewise with panic_runtime.w, `ptr` a runtime local name.
fn make_str(): "the program's make_str"
fn str_data(): 3
fn ptr(): 7

fn main:
    print(make_str())
    print(f"{str_data()} {ptr()}")
    var v: List[str] = List.new()
    v.push("a" ++ "b")
    print(v.join("-"))
