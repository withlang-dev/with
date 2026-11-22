//! expect-stdout: got one
//! expect-stdout: name one
//! expect-stdout: after match
//! expect-stdout: drop one
//! expect-stdout: 2

// §9.7: whether a subject is owned is decided by its root, and a by-value
// parameter is an owned root. An element of the parameter is still observed:
// a pattern never moves a payload out of a list element, which would drop
// it twice (once as the binding, once with the list).
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

enum E:
    A(t: Tag)
    B

fn f(xs: List[E]) -> i32:
    match xs[0]:
        .A(t) => print(f"got {t.name}")
        .B => print("b")
    match xs[0]:
        .A(Tag { name }) => print(f"name {name}")
        .B => print("b")
    print("after match")
    xs.len() as i32

fn main:
    let n = f([E.A(Tag { name: "one" }), E.B])
    print(n)
