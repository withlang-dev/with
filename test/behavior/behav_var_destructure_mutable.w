//! expect-stdout: 14 6
//! expect-stdout: 5 8 2
//! expect-stdout: 2 9 1 2
//! expect-stdout: 11 6
//! expect-stdout: 2 6
//! expect-stdout: 33
//! expect-stdout: 100 3 1 2
//! expect-stdout: 6 ello 2 3 yz
//! expect-stdout: 32 -1

// #1354 (§9.7: "All pattern forms are available in `let`/`var` bindings"):
// `var PATTERN = ...` binds every name the pattern introduces mutably —
// reassignment, compound assignment and D12 `mut fn` receivers on scalar and
// str bindings — across tuple, nested tuple, named and anonymous struct,
// wildcard and refutable (`else`) patterns. The bindings are fresh locals:
// mutating one never writes through to the subject (`t`, `p` below).

type P { x: i32, y: i32 }
type Q { x: i32, y: i32, z: i32 }

extend i32:
    mut fn bump(): self += 1
extend str:
    mut fn behead(): self = self.slice(1, self.len())

fn lc(b: i32) -> (i32, i32): (b + 1, b + 2)
fn find(k: i32) -> Option[i32]: if k > 0: Some(k * 10) else: None

fn refutable(k: i32) -> i32:
    var Some(n) = find(k) else: return -1
    n += 1
    var .Some(m) = find(k) else: return -2
    m = m * 2
    n + m + 1

fn main:
    var (x, y) = lc(3)
    x = x + 10
    y += 1
    print(f"{x} {y}")

    var ((a, b), c) = ((1, 2), 3)
    a = 5
    b *= 4
    c -= 1
    print(f"{a} {b} {c}")

    let p = P { x: 1, y: 2 }
    var P { x: px, y: py } = p
    px += 1
    py = 9
    print(f"{px} {py} {p.x} {p.y}")

    var { x: qx, y: qy, .. } = Q { x: 1, y: 2, z: 3 }
    qx += 10
    qy = qy * 3
    print(f"{qx} {qy}")

    var (w, _, z) = (1, "dropped".clone(), 3)
    w += 1
    z = z * 2
    print(f"{w} {z}")

    var total = 0
    for i in 0..3:
        var (lo, hi) = (i, i * 10)
        lo += 1
        hi -= 1
        total += lo + hi
    print(f"{total}")

    let t = (1, 2)
    var (t0, t1) = t
    t0 = 100
    t1 += 1
    print(f"{t0} {t1} {t.0} {t.1}")

    var (n, s) = (5, "hello")
    n.bump()
    s.behead()
    var (m, (k, u)) = (1, (2, "xyz"))
    m.bump()
    k.bump()
    u.behead()
    print(f"{n} {s} {m} {k} {u}")

    print(f"{refutable(1)} {refutable(0)}")
