//! expect-debug-alloc: leak count=0

// #1392: the built-in display of an enum or struct joins its parts — the
// variant name, each payload's own display, the separators — and every join
// but the last result, and every payload's display, is an intermediate the
// result supersedes. Each one leaked: IoError.to_str() (the `error`
// declaration's generated Display, `f"{self}"`) lost five blocks per call.
// A str payload is copied before it is joined, so the copy — never the
// payload the value still owns — is what the join frees; the payload reads
// after formatting are the controls.

use std.fs
use std.collections.HashMap

error AppErr =
    | Os(code: i32, path: str)
    | Plain
    | Pair(a: i32, b: i32)

enum E:
    A(i32, str)
    B

enum Outer:
    Wrap(E)
    Pair(str, Option[str])

type S { e: E, n: i32, t: str }

fn mk(k: i32) -> AppErr:
    if k == 0: return .Os(2, "/tmp/x" ++ "y")
    if k == 1: return .Plain
    .Pair(3, 4)

fn main:
    match read_file("/tmp/does-not-exist-1392"):
        Ok(s) => print(s.len())
        Err(e) =>
            let m = e.to_str()
            print(m.len() > 0)
    for k in 0..3:
        let e = mk(k)
        print(f"{e} {e:?}")
        print(e.display())
        print(mk(k).to_str())
        print(mk(k).debug_str())
        match e:
            .Os(_, p) => print(p)
            _ => print("-")
        let o = if k == 0: Outer.Wrap(E.A(k, "n" ++ "m")) else: Outer.Pair("p" ++ "q", if k == 1: Some("s" ++ "t") else: None)
        print(f"{o} {o:?}")
        let r: Result[str, i32] = if k == 0: Err(7) else: Ok("o" ++ "k")
        print(f"{r}")
        let s = S { e: E.A(k, "x" ++ "z"), n: k, t: "t" ++ "u" }
        print(f"{s:?}")
        print(s.t)
        var m: HashMap[str, str] = HashMap.new()
        m.insert("a".clone(), "b" ++ "c")
        let g = m.get(if k == 0: "a" else: "z")
        print(f"{g}")
        print(m.get("a").unwrap())
