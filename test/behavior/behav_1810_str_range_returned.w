//! expect-stdout: bc
//! expect-stdout: bc
//! expect-stdout: c
//! expect-stdout: ell
//! expect-stdout: a b
//! expect-stdout: none
//! expect-stdout: llo

// #1810 / #1587 (D71 §4.8a): a range of a `&str` is a `&str` view with its
// base's origin, and a `&str` is its own `{ptr, len}`, so the view returns
// like any view (§21.1 Rule 6): its origin is the parameter, and it reads
// the caller's bytes. It was refused by name ("a string slice cannot be
// returned yet") while a `&str` pointed at a header, because the range's
// header lived in the callee's frame.
fn tail(s: &str) -> &str: s[1..]

fn tail_bound(s: &str) -> &str:
    let t = s[1..]
    t

fn inner(s: &str) -> Option[&str]: if s.len() > 2: Some(s[1..s.len() - 1]) else: None

fn halves(s: &str) -> (&str, &str): (s[..1], s[2..])

fn main:
    print(tail("abc"))
    print(tail_bound("abc"))
    print(tail(tail("abc")))
    let owned = "hello"
    print(inner(owned).unwrap())
    let (a, b) = halves("a-b")
    print(f"{a} {b}")
    if inner("ab").is_none(): print("none")
    let v = tail(owned)
    print(v[1..])
