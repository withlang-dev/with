//! expect-stdout: Some(4)
//! expect-stdout: Some(xyz)
//! expect-stdout: Some(7) Some(pq)
//! expect-stdout: Some(3) Some(3) abc
//! expect-stdout: 4 xyz
// #1710 (§10.3): an optional chain observes its receiver. A chain that
// copies a Copy field out (`o?.b`, `t?.1`), or lends the payload to a
// borrowing method (`s?.len()`), reads through the receiver's place. MIR
// moved the whole Option into a temporary and reset it, so the next chain
// on the same Option read `Some()` — a silent wrong value.

type P { a: str, b: i32 }

fn main:
    let o: Option[P] = Some(P { a: "xyz".clone(), b: 4 })
    print(f"{o?.b}")
    print(f"{o?.a}")
    let t: Option[(str, i32)] = Some(("pq".clone(), 7))
    let first = t?.1
    print(f"{first} {t?.0}")
    let s: Option[str] = Some("abc".clone())
    let n1 = s?.len()
    let n2 = s?.len()
    print(f"{n1} {n2} {s.unwrap()}")
    let q: Option[P] = Some(P { a: "xyz".clone(), b: 4 })
    let b = q?.b ?? 0
    match q:
        Some(p) => print(f"{b} {p.a}")
        None => print("none")
