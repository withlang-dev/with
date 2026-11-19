//! expect-stdout: head a rest 1
//! expect-stdout: got e
//! expect-stdout: some
//! expect-stdout: after param
//! expect-stdout: drop P
//! expect-stdout: drop e
//! expect-stdout: drop a
//! expect-stdout: drop b
//! expect-stdout: 7
//! expect-stdout: head m1 rest 1
//! expect-stdout: drop P
//! expect-stdout: drop e
//! expect-stdout: drop m1
//! expect-stdout: drop m2
//! expect-stdout: after temporary
//! expect-stdout: head s1 rest 0
//! expect-stdout: after receiver
//! expect-stdout: drop P
//! expect-stdout: drop e
//! expect-stdout: drop s1
//! expect-stdout: 3

// §9.7 (Eric, 2026-11-19): a field or an element is a place whatever it is
// under. A pattern on a field of a by-value parameter, of a temporary or of
// a `move fn` receiver observes the field, as it does on a local; the owner
// stays whole and drops once. (It was refused as an implicit move out of a
// field, even when the arms only inspected, so the program needed
// `var q = p` to say nothing.)
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

enum E:
    A(t: Tag)
    B

type P { items: List[Tag], e: E, n: i32 }
impl Drop for P:
    move fn drop(): print("drop P")

fn make(a: str, b: str, n: i32) -> P: P { items: [Tag { name: a }, Tag { name: b }], e: E.A(Tag { name: "e" }), n: n }

fn by_parameter(p: P) -> i32:
    match p.items:
        [h, ..rest] => print(f"head {h.name} rest {rest.len()}")
        [] => print("none")
    match p.e:
        .A(t) => print(f"got {t.name}")
        .B => print("b")
    match p.items:
        [] => print("none")
        _ => print("some")
    print("after param")
    p.n

fn by_temporary:
    match make("m1", "m2", 1).items:
        [h, ..rest] => print(f"head {h.name} rest {rest.len()}")
        [] => print("none")
    print("after temporary")

impl P:
    move fn eat() -> i32:
        match self.items:
            [h, ..rest] => print(f"head {h.name} rest {rest.len()}")
            [] => print("none")
        print("after receiver")
        self.n

fn main:
    print(by_parameter(make("a", "b", 7)))
    by_temporary()
    let fed = P { items: [Tag { name: "s1" }], e: E.A(Tag { name: "e" }), n: 3 }.eat()
    print(fed)
