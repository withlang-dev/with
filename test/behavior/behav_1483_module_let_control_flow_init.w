//! expect-stdout: true false 7 11
//! expect-stdout: true
// #1483: a module-level `let` whose initializer has control flow (`or`,
// `and`, `if`, `match`) is computed by a synthesized initializer function.
// Its switch lowering's shared default block was never terminated there,
// and LLVM verification failed. A trait default method is the other
// synthesized body; it now ends through the same helper.

let Y: i32 = 100
let Z: bool = (Y == 3) or (Y == 100)
let A: bool = (Y > 50) and (Y < 60)
let X: i32 = if Y == 100: 7 else: 3
let M: i32 = match Y:
    100 => 11
    _ => 0

trait Pick:
    fn code(self: &Self) -> i32
    fn either(self: &Self) -> bool: self.code() == 1 or self.code() == 2

type W { n: i32 }

impl Pick for W:
    fn code(self: &Self) -> i32: self.n

fn main:
    print(f"{Z} {A} {X} {M}")
    let w = W { n: 2 }
    print(f"{w.either()}")
