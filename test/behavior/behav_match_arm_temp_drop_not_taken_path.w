//! expect-stdout: 0
//! expect-stdout: 1
//! expect-stdout: 2

// #729 class, match arms: a temp created INSIDE one arm — a call result, or a
// default-argument value such as assert's message — must drop inside that arm.
// Registered in the enclosing statement frame, its drop landed in the match's
// join block (the function's exit block for a tail match), and every other
// arm's path freed an uninitialized temp: with -O1 slot reuse the garbage was a
// live heap pointer (spec_ss06's SlotMap values buffer), a double free. Each
// shape below takes the arm WITHOUT the temp and must run clean.
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

fn note(n: i32, tag: &str = "note") -> i32:
    tag.len() as i32 + n

fn main:
    let seed: Vec[str] = Vec.new()
    seed.push("x")
    var big = Big { a: cl(&seed), b: cl(&seed) }
    var results: Vec[i32] = Vec.new()
    let n = big.a.len() as i32

    // Temp-bearing arm first, taken arm second.
    match n:
        99 => results.push(consume(clone_big(&big)))
        _ => results.push(0)
    print_i32(results.get(0))

    // Taken arm first, temp-bearing arm second (the drop of the second arm's
    // temp is what the tail-position match scheduled at function exit).
    match n:
        1 => results.push(1)
        _ => results.push(consume(clone_big(&big)))
    print_i32(results.get(1))

    // Default-argument temporaries (assert's message shape) in both arms of a
    // tail-position match over an Option view, plus a guard with a temp.
    let opt: Option[i32] = Some(2)
    match opt:
        Some(v) if note(v, "guard" ++ "") > 0 => assert(v == 2, "two" ++ "")
        Some(_) => assert(false, "wrong arm" ++ "")
        None => assert(false)
    print_i32(2)
