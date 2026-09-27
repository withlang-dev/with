//! expect-stdout: before abcd after zzzz
//! expect-stdout: last abcd
//! expect-stdout: inner 7
//! expect-stdout: ok

// §21.1 Rule 4 (#1722): a view's liveness reaches the blocks enclosing a
// write and a loop's next iteration, and no further: a view whose last use
// is behind the loop, a write that leaves the loop at once, and a view
// declared inside the loop body are all accepted.
type S { s: str, n: i32 }

fn dead_before_loop() -> str:
    var x = S { s: "ab" ++ "cd", n: 0 }
    let p = x.s
    let before = f"before {p}"
    var k = 0
    while k < 2:
        if k == 1:
            x.s = "zz" ++ "zz"
        k += 1
    f"{before} after {x.s}"

fn break_after_write() -> str:
    var x = S { s: "ab" ++ "cd", n: 0 }
    let p = x.s
    var seen = ""
    var k = 0
    while k < 5:
        seen = p.clone()
        if k == 1:
            x.s = "zz" ++ "zz"
            break
        k += 1
    f"last {seen}"

fn view_inside_loop() -> i32:
    var x = S { s: "ab" ++ "cd", n: 0 }
    var total = 0
    for i in 0..2:
        let p = x.s
        total += p.len() as i32
        x.s = "zz" ++ "z"
    total

fn main:
    print(dead_before_loop())
    print(break_after_write())
    print(f"inner {view_inside_loop()}")
    print("ok")
