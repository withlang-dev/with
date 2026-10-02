//! expect-stdout: 0

// #729 residue pin: a call-result temp created INSIDE one if-branch must
// drop inside that branch. Registered in the enclosing statement frame, its
// drop landed in the join block, and the not-taken path freed an
// uninitialized temp (invalid free of stack garbage; release-only via -O1
// slot reuse). The else path here must run clean.
use std.builtins.print_i32
type Big { a: Vec[str], b: Vec[str] }

fn cl(v: &Vec[str]) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    for i in 0..v.len() as i32:
        out.push(v[i].clone())
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
    if big.a.len() as i32 == 99:
        results.push(consume(clone_big(&big)))
    else:
        results.push(0)
    print_i32(results[0])
