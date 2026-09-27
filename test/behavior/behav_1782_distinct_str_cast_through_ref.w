//! expect-stdout: abc
//! expect-stdout: 3
//! expect-stdout: xyz

// #1782 (§4.5 zero-cost distinct wrappers, §3.7): a cast through a reference
// reads what the reference names. `r as str` with `r: &Name` (`Name =
// distinct str`) cast the reference VALUE (a pointer) to the string header
// and printed a garbage byte; `r as []u8` already read through.
// The strings are literals on purpose: the ownership of a non-Copy value
// cast into or out of a distinct wrapper is a separate defect (a `Name`
// drop is a no-op and `s as Name` leaves the buffer with `s`), so a cloned
// string here would double free under the debug allocator.
type Name = distinct str
type Tag = distinct str

fn show(n: &Name): print(n as str)
fn width(n: &Name): print((n as []u8).len())
fn retag(n: &Name): print((n as Tag) as str)

fn main:
    let n = "abc" as Name
    show(n)
    width(n)
    let t = "xyz" as Name
    retag(t)
