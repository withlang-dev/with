//! expect-stdout: abc
//! expect-stdout: 3
//! expect-stdout: xyz

// #1782 (§4.5 zero-cost distinct wrappers, §3.7): a cast through a reference
// reads what the reference names. `r as str` with `r: &Name` (`Name =
// distinct str`) cast the reference VALUE (a pointer) to the string header
// and printed a garbage byte; `r as []u8` already read through.
// D75 (#1802): the cast through the reference is a view of the caller's
// string (`&str`), and `s as Name` moves the owned string into the wrapper,
// so the owned strings here are freed once each.
type Name = distinct str
type Tag = distinct str

fn show(n: &Name): print(n as str)
fn width(n: &Name): print((n as []u8).len())
fn retag(n: &Name): print((n as Tag) as str)

fn main:
    let n = "abc".clone() as Name
    show(n)
    width(n)
    let t = "xyz".clone() as Name
    retag(t)
