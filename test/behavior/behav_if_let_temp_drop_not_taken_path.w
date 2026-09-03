//! expect-stdout: 0
//! expect-stdout: 1

// #729 class, if-let: a temp created inside one branch of an `if let` must
// drop on that branch's path, never at the join where the other path would
// free an uninitialized temp. Both orders: the temp in the not-taken `then`,
// and the temp in the not-taken `else`.
use std.builtins.print_i32
type Big { a: Vec[str], b: Vec[str] }

fn cl(v: &Vec[str]) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    for i in 0..v.len() as i32:
        out.push(v.get(i as i64) ++ "")
    out

fn clone_big(r: &Big) -> Big:
    Big { a: cl(&r.a), b: cl(&r.b) }

fn consume(b: Big) -> i32:
    b.a.len() as i32

fn main:
    let seed: Vec[str] = Vec.new()
    seed.push("x")
    var big = Big { a: cl(&seed), b: cl(&seed) }
    var results: Vec[i32] = Vec.new()
    let none: Option[i32] = None
    let some: Option[i32] = Some(1)

    if let Some(_) = none:
        results.push(consume(clone_big(&big)))
    else:
        results.push(0)
    print_i32(results.get(0))

    if let Some(v) = some:
        results.push(v)
    else:
        results.push(consume(clone_big(&big)))
    print_i32(results.get(1))
