//! expect-check-fail: impl method `eq2` takes 2 parameter(s), and trait `Equal` declares 1 (D140)
// #988 (D140): an impl method takes the trait's parameters. One with an
// extra parameter was accepted at the impl and refused only at a call.
trait Equal:
    fn eq2(self: &Self, other: &Self) -> bool

type Box2:
    n: i32

impl Equal for Box2:
    fn eq2(other: &Self, extra: i32) -> bool: true

fn main:
    print("impl accepted")
