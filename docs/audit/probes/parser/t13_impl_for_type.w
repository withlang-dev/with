// T13: `impl Trait for Target` written in TYPE position — Parser.w:7707-7710
// parses the target and silently discards it.
trait Show:
    fn show(x: i32) -> i32

fn takes(x: impl Show for Foo) -> i32:
    0

fn main:
    assert(takes(0) == 0)
