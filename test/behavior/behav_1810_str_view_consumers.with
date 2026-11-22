//! expect-stdout: 5
//! expect-stdout: 104
//! expect-stdout: true
//! expect-stdout: true
//! expect-stdout: 2
//! expect-stdout: ell
//! expect-stdout: eq-lit
//! expect-stdout: eq-str
//! expect-stdout: eq-ref
//! expect-stdout: ne
//! expect-stdout: lt
//! expect-stdout: fmt hello|  hello|"hello"
//! expect-stdout: hello!
//! expect-stdout: hello
//! expect-stdout: HELLO
//! expect-stdout: matched hello
//! expect-stdout: 7
//! expect-stdout: bytes 5
//! expect-stdout: owned hello 5

// #1810: consumers of a `&str` view value — length, byte index, str
// methods through the view, every comparison spelling, formatting, owned
// demands (clone, concat, annotation), literal patterns, map keys.

use std.collections.HashMap

fn check(h: &str):
    print(h.len())
    print(h[0])
    print(h.starts_with("he"))
    print(h.contains("ll"))
    print(h.find("l"))
    print(h.slice(1, 4))
    if h == "hello": print("eq-lit")
    let other = "hello"
    if h == other: print("eq-str")
    let hr: &str = other
    if h == hr: print("eq-ref")
    if h != "world": print("ne")
    if h < "world": print("lt")
    print(f"fmt {h}|{h:>7}|{h:?}")
    print(h ++ "!")
    let c: str = h
    print(c)
    print(h.to_upper())
    match h:
        "bye" => print("no")
        "hello" => print("matched hello")
        _ => print("other")
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("hello", 7)
    print(m.get(h) ?? 0)
    var n = 0
    for _ in 0..h.len(): n = n + 1
    print(f"bytes {n}")
    let owned: str = h
    print(f"owned {owned} {owned.len()}")

fn main:
    check("hello")
