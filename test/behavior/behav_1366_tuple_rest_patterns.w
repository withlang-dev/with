//! expect-stdout: 10 1 2 3
//! expect-stdout: 1 4 2 3
//! expect-stdout: a c bb
//! expect-stdout: first:x rest:y,z
//! expect-stdout: pair 1 9
//! expect-stdout: done
//! expect-stdout: 5 6
//! expect-stdout: 7

// #1366 (§9.7 `let (head, ..tail) = get_items()`, "..rest captures
// remaining"): a tuple pattern takes one `..`, anywhere in the list. A bare
// `..` skips the elements it covers; `..name` binds them as a tuple. In let,
// in match arms (with a guard that fails first), with owned str elements
// that must drop once, over a borrowed tuple, and at comptime.
fn items -> (i32, i32, i32): (1, 2, 3)

fn describe(t: (str, str, str)) -> str:
    match t:
        (h, ..rest) if rest.0.len() > 5 => "long " ++ h
        (h, ..rest) => f"first:{h} rest:{rest.0},{rest.1}"

fn ends(t: &(i32, i32, i32, i32)) -> str:
    match t:
        (0, ..) => "zero"
        (a, .., z) => f"pair {a} {z}"

comptime fn middle_sum() -> i32:
    let (_, ..mid, _) = (1, 3, 4, 9)
    mid.0 + mid.1

fn main:
    let (a, ..) = (10, 20, 30)
    let (h, ..tail) = items()
    print(f"{a} {h} {tail.0} {tail.1}")
    let (first, .., last) = (1, 2, 3, 4)
    let (_, ..inner, _) = (1, 2, 3, 4)
    print(f"{first} {last} {inner.0} {inner.1}")
    let (x, ..rest) = ("a".clone(), "bb".clone(), "c".clone())
    let (mid, end) = rest
    print(f"{x} {end} {mid}")
    print(describe(("x".clone(), "y".clone(), "z".clone())))
    print(ends(&(1, 5, 6, 9)))
    print("done")
    let (p, q, ..none) = (5, 6)
    let u: () = none
    print(f"{p} {q}")
    print(f"{middle_sum()}")
