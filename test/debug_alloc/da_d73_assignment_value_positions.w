//! expect-debug-alloc: leak count=0
//! expect-stdout: nested 3 3
//! expect-stdout: cond 1 2 3
//! expect-stdout: view x! x!
//! expect-stdout: after y! x!
//! expect-stdout: field 7 7
//! expect-stdout: ok

// §9.1 / D73 (#1479): an assignment in any value position yields a read of
// its place after the store — a view: a Copy demand copies (`a = b = 3`,
// `while (n = next()) != 0`), a non-Copy place binds a view (`let t = (s =
// e)`: `t` reads what `s` holds, `s` stays the owner). Nothing is duplicated.

var ticks = 0
fn next() -> i32:
    ticks += 1
    if ticks > 3: 0 else: ticks

fn compute(s: &str): s.clone() ++ "!"

type P { n: i32 }

fn main:
    var a = 0
    var b = 0
    a = b = 3
    print(f"nested {a} {b}")
    var n = 0
    var seen = ""
    while (n = next()) != 0:
        seen = seen ++ f" {n}"
    print(f"cond{seen}")
    var s = "".clone()
    let t = (s = compute("x"))
    print(f"view {t} {s}")
    let u = compute("y")
    print(f"after {u} {s}")
    var p = P { n: 0 }
    var q = 0
    q = p.n = 7
    print(f"field {q} {p.n}")
    print("ok")
