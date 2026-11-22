//! expect-stdout: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
//! expect-stdout: 2
//! expect-stdout: a
//! expect-stdout: 1

// #3461: a list of values is a value (D111, D120), so the parameter may be
// used again after a list pattern took a copy of it apart. The copy shares
// the buffer until elements leave it: it gets its own first (taking an
// element out of the shared one gave it two owners, a double free), and the
// parameter keeps its own count and its drop (cancelling it leaked).
type Tag { name: str }

fn strings(xs: List[str]) -> i32:
    match xs:
        [h, ..rest] => print(h)
        [] => print("none")
    xs.len() as i32

fn records(xs: List[Tag]) -> i32:
    match xs:
        [h, ..rest] => print(h.name)
        [] => print("none")
    xs.len() as i32

fn main:
    print(strings(["a".repeat(30), "b".repeat(30)]))
    print(records([Tag { name: "a" }]))
