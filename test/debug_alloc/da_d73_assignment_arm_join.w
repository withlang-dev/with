//! expect-debug-alloc: leak count=0
//! expect-stdout: y! y!
//! expect-stdout: n! n!
//! expect-stdout: ok

// §9.1 / D73 (#1479), §3.8 join rules: an `if` whose arms are assignments
// to the same non-Copy place yields a view of that place — `let t = if p:
// s = e1 else: s = e2` binds a view of `s`, as `if p: x.s else: y.s` binds a
// field view. The base lowered each arm's operand as a second owner of the
// stored buffer (DOUBLE FREE).

fn compute(s: &str): s ++ "!"

fn pick(p: bool):
    var s = ""
    let t = if p: s = compute("y") else: s = compute("n")
    print(f"{t} {s}")

fn main:
    pick(true)
    pick(false)
    print("ok")
