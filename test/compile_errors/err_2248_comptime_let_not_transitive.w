//! expect-error: symbol 'HIDDEN' is not visible from this module
// #2248 (§18.2): imports are not transitive in a comptime subject, as at run
// time. The evaluator found every module's `let` by name, so this printed 1
// while `print(HIDDEN)` in the same module was refused.
use issue2248.a

const B: i32 = comptime match HIDDEN:
    8 => 1
    _ => 2

fn main: print(B)
