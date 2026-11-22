//! expect-stdout: true
//! expect-stdout: false
//! expect-stdout: false
//! expect-stdout: false
//! expect-stdout: false

// #3483 (D110): `List.is_empty` is declared in the standard library; the
// compiler has no built-in of that name. A call on a list, through a
// reference, on a list of str, and the method as a value all read it.
fn main:
    let xs: List[i32] = []
    print(xs.is_empty())
    let ys = [1]
    print(ys.is_empty())
    let r = &ys
    print(r.is_empty())
    let f = List[i32].is_empty
    print(f(ys))
    let ss = ["a"]
    print(ss.is_empty())
