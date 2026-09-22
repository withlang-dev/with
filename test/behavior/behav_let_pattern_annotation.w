//! expect-stdout: 1 2 5000000005 3 3 4
//! expect-stdout: 26 -1 2 8

// §30.4 `LET_STMT := 'let' PATTERN [ ':' TYPE ] '=' EXPR`: a pattern let may
// annotate the whole subject. The annotation demands that type and drives the
// subject's inference (`(1, 2)` becomes `(i64, i64)`), on `var` too, on a
// refutable `else` pattern, and on a named struct pattern (#1354).

type P { x: i64, y: i64 }

fn pair -> (i32, i32): (3, 4)

fn run(k: i32) -> i64:
    let Some(n): Option[i64] = if k > 0: Some(5) else: None else: return -1
    var P { x, y }: P = P { x: 1, y: 2 }
    x += n
    y *= 10
    x + y

fn main:
    let (a, b): (i64, i64) = (1, 2)
    var (c, d): (i64, i64) = (5, 6)
    c += 5000000000
    d = a + b
    let (e, f): (i32, i32) = pair()
    print(f"{a} {b} {c} {d} {e} {f}")

    let x: i32 = 7
    var (g, h): (i64, i64) = (1, x)
    g += 1
    h += 1
    print(f"{run(1)} {run(0)} {g} {h}")
