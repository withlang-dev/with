//! expect-stdout: 3 7 11
//! expect-stdout: 1
//! expect-stdout: 2
//! expect-stdout: 3
//! expect-stdout: 3 7
//! expect-stdout: 2 4 6
//! expect-stdout: 2 4 6

// #2343 (§4.2.1 D128, §4.3c D93, §13.6): a comprehension's binding is typed
// by its uses, and a loop or clause binding over a literal's binding
// carries a demand to that literal, a tuple pattern position by position.
// `assert_list_i32(sums, …)` says `[]i32`, so `sums` is a `List[i32]`, its
// body `a + b` is `i32`, and `src` is a `List[(i32, i32)]`; nothing is
// annotated or cast.
fn assert_list_i32(xs: []i32, a: i32, b: i32, c: i32):
    print(f"{xs[0] * (if xs[0] == a: 1 else: 0)} {xs[1] * (if xs[1] == b: 1 else: 0)} {xs[2] * (if xs[2] == c: 1 else: 0)}")

fn narrow(x: i32): print(x)
fn show(xs: []i32): print(f"{xs[0]} {xs[1]} {xs[2]}")

fn main:
    let src = [(1, 2), (3, 4), (5, 6)]
    let sums = [a + b for (a, b) in src]
    assert_list_i32(sums, 3, 7, 11)
    // a loop binding over a literal's binding
    let ones = [1, 2, 3]
    for x in ones: narrow(x)
    // a tuple pattern over a literal's binding, in a loop
    let pairs = [(1, 2), (3, 4)]
    var line = ""
    for (p, q) in pairs: line = line ++ f"{narrow_sum(p, q)} "
    print(line.trim())
    // a plain clause over a literal's binding, and over a literal
    let base = [1, 2, 3]
    let doubled = [x * 2 for x in base]
    show(doubled)
    let inline = [x * 2 for x in [1, 2, 3]]
    show(inline)

fn narrow_sum(a: i32, b: i32) -> i32: a + b
