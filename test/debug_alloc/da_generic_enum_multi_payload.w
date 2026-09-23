//! expect-debug-alloc: leak count=0
// #1441: a generic enum variant with two or more payload fields, built and
// matched with owned payloads: bound by value, bound through a reference,
// dropped whole. Each owned payload is freed exactly once.

enum P[A, B]:
    Both(a: A, b: B)
    Left(a: A)
    Neither

fn joined(p: P[str, str]) -> str:
    match p:
        .Both(a, b) => a ++ b
        .Left(a) => a
        .Neither => "".clone()

fn lens(p: &P[str, str]) -> i64:
    match p:
        .Both(a, b) => a.len() + b.len()
        .Left(a) => a.len()
        .Neither => 0

fn main:
    print(joined(P.Both("ab".clone(), "cd".clone())))
    let kept: P[str, str] = P.Both("xyz".clone(), "w".clone())
    print(lens(kept))
    let whole: P[str, str] = P.Both("dropped".clone(), "unmatched".clone())
    print(lens(whole))
