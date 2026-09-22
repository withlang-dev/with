//! expect-stdout: S.B("x")
//! expect-stdout: S.C(7, "y")
//! expect-stdout: S.A
//! expect-stdout: Wrap { tag: S.C(7, "y"), n: 1 }
//! expect-stdout: Level.High
//! expect-stdout: x
//! expect-stdout: y 7

// #1289: `@[derive(Debug, Clone)]` on an enum generates the impls for data
// enums (§11.8's own example derives on an enum); it used to be accepted
// and generate nothing. Payload names are positional in the Debug form
// (the parser keeps no payload names). Clone clones a non-Copy payload
// and reads a Copy one; `derive(all)` on an enum takes Debug and Clone.

@[derive(Debug, Clone)]
enum S { A | B(str) | C(code: i32, label: str) }

@[derive(all)]
type Wrap { tag: S, n: i32 }

@[derive(all)]
enum Level: i32 { Low = 1 | High = 2 }

fn main:
    let s = S.B("x")
    let t = s.clone()
    print(t.debug_str())
    let c = S.C(7, "y")
    let d = c.clone()
    print(d.debug_str())
    let a = S.A
    print(a.clone().debug_str())
    let w = Wrap { tag: c, n: 1 }
    let w2 = w.clone()
    print(w2.debug_str())
    let high = Level.High
    print(high.clone().debug_str())
    // The clone is independent of its source: the source still reads whole.
    match s:
        B(v) => print(v)
        _ => print("wrong")
    match d:
        C(n, v) => print(f"{v} {n}")
        _ => print("wrong")
