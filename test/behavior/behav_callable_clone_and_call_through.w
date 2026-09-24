//! expect-stdout: a!
//! expect-stdout: b!
//! expect-stdout: 5
//! expect-stdout: 5
//! expect-stdout: abc

// D63 (§12.4): calling through a binding observes it (no move); `.clone()`
// is free for a bare function and for a non-move closure, and clones the
// owned environment of a `move ||` closure (its str capture is cloned).
fn shout(s: &str) -> str: s.clone() ++ "!"
fn once(f: fn() -> i32) -> i32: f()

fn main:
    let f = shout
    print(f("a"))
    let g = f.clone()
    print(g("b"))
    let s = "hello".clone()
    let len = move () => s.len() as i32
    let len2 = len.clone()
    print(once(len))
    print(once(len2))
    let t = "abc".clone()
    let view = () => t.len() as i32
    let view2 = view.clone()
    let _ = view2()
    print(t)
