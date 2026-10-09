//! expect-debug-alloc: leak count=0
//! expect-stdout: ref none 0
//! expect-stdout: ref some 3
//! expect-stdout: ref err 0
//! expect-stdout: recv none 0
//! expect-stdout: recv ok 3
//! expect-stdout: dq recv 0
//! expect-stdout: dq ref 0
//! expect-stdout: map ref 0
//! expect-stdout: owned arg 0
//! expect-stdout: if ref 0
//! expect-stdout: match recv 0

// #1393 (§3.8/§10 join): a join arm that is a constructor with no expected
// type (`List.new()`) is typed as the bare generic `List` until the join
// settles it. The settled type was never recorded on the arm, so lowering it
// leaned on the surrounding expectation: under `&` (expected `&List[i32]`) or
// as a method receiver (no expectation) MIR could not type `List.new()` —
// "[mir-lower-fail] kind=27", "code generation failed".
// Covers: unwrap_or on Option/Result × both paths under `&` and as a
// receiver, `??` as a receiver and under `&`, HashMap, an owned call
// argument, and `if` / `match` arms under `&` and as a receiver.
use std.collections
use std.process

fn mkv(n: i32) -> List[i32]:
    var xs: List[i32] = List.new()
    for i in 0..n: xs.push(i)
    xs

fn ov(ok: bool) -> Option[List[i32]]:
    if not ok: return None
    Some(mkv(3))

fn rv(ok: bool) -> Result[List[i32], str]:
    if not ok: return Err("no" ++ "pe")
    Ok(mkv(3))

fn om() -> Option[HashMap[str, i32]]: None

fn count(t: &List[i32]): t.len()
fn take(t: List[i32]): t.len()

fn main:
    let a = ov(false)
    print(f"ref none {count(&a.unwrap_or(List.new()))}")
    let b = ov(true)
    print(f"ref some {count(&b.unwrap_or(List.new()))}")
    let c = rv(false)
    print(f"ref err {count(&c.unwrap_or(List.new()))}")
    print(f"recv none {ov(false).unwrap_or(List.new()).len()}")
    print(f"recv ok {rv(true).unwrap_or(List.new()).len()}")
    let d = ov(false)
    print(f"dq recv {(d ?? List.new()).len()}")
    let e = rv(false)
    print(f"dq ref {count(&(e ?? List.new()))}")
    print(f"map ref {om().unwrap_or(HashMap.new()).len()}")
    print(f"owned arg {take(ov(false).unwrap_or(List.new()))}")
    let xs = mkv(1)
    let big = args().len() > 100
    print(f"if ref {count(&(if big: xs else: List.new()))}")
    let m = match big:
        true => mkv(2)
        false => List.new()
    print(f"match recv {m.len()}")
