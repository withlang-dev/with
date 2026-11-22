//! expect-stdout: drop c
//! expect-stdout: drop d
//! expect-stdout: 1 2 103 104
//! expect-stdout: drop cc
//! expect-stdout: cc
//! expect-stdout: drop dd
//! expect-stdout: dd
//! expect-stdout: drop big
//! expect-stdout: 12
//! expect-stdout: drop bigd
//! expect-stdout: 13
//! expect-stdout: drop small
//! expect-stdout: 1
//! expect-stdout: drop smalld
//! expect-stdout: 2

// #823 (§9.7): the alternatives of an or-pattern bind the same names and
// the arm sees one binding per name. A Copy payload, a payload with a
// destructor (moved once, dropped once), and a guard: when it fails the
// value goes back to the subject and the next arm binds it again.
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

enum E:
    A(n: i32, s: str)
    B(s: str, n: i32)
    C(t: Tag, n: i32)
    D(n: i32, t: Tag)
    None0

fn num(e: E) -> i32:
    match e:
        .A(n, _) | .B(_, n) => n
        .C(_, n) | .D(n, _) => n + 100
        .None0 => 0

fn tag_name(e: E) -> str:
    match e:
        .C(t, _) | .D(_, t) => t.name
        _ => "none"

fn guarded(e: E) -> i32:
    match e:
        .C(t, n) | .D(n, t) if n > 5 => n + t.name.len() as i32
        .C(t, _) => 1
        .D(_, t) => 2
        _ => 3

fn main:
    print(f"{num(.A(1, "x"))} {num(.B("y", 2))} {num(.C(Tag { name: "c" }, 3))} {num(.D(4, Tag { name: "d" }))}")
    print(tag_name(.C(Tag { name: "cc" }, 1)))
    print(tag_name(.D(1, Tag { name: "dd" })))
    print(guarded(.C(Tag { name: "big" }, 9)))
    print(guarded(.D(9, Tag { name: "bigd" })))
    print(guarded(.C(Tag { name: "small" }, 1)))
    print(guarded(.D(1, Tag { name: "smalld" })))
