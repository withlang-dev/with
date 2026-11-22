//! expect-stdout: ok

// #549 guard-rails: the if-branch unify diagnostic is value-position only.
// Statement-position ifs with mixed branch types and value-position joins
// of a distinct type against its base stay accepted.

type BlockId = distinct i32
fn s() -> str: "a"
fn n() -> i32: 1
fn mk() -> BlockId: BlockId(7)

fn main:
    if true: s() else: n()
    let b = if true: mk() else: 0
    print("ok")
