//! expect-stdout: 0 3 5 7 -1 2.5 1
//! expect-stdout: ok

// #2567 (§4.5): an unsuffixed numeric literal where a distinct type over a
// number is demanded takes the distinct type, at a return, a binding, a
// parameter, a field, a negation, a float distinct and an untyped constant.
type Id = distinct i32
type Meters = distinct f64
type S { a: Id }
const ONE = 1

fn none() -> Id: 0
fn three() -> Id:
    return 3
fn f(x: Id) -> bool: x != 0
fn show(x: Id): x.value

fn main:
    let five: Id = 5
    let s = S { a: 7 }
    let neg: Id = -1
    let m: Meters = 2.5
    let one: Id = ONE
    print(f"{show(none())} {show(three())} {show(five)} {show(s.a)} {show(neg)} {m.value} {show(one)}")
    if f(3) and not f(0): print("ok")
