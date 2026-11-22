//! expect-stdout: 33
//! expect-stdout: 1
//! expect-stdout: 41
//! expect-stdout: 77

// #1569 (§4.2.1 rule 2): a literal argument to a static generic method takes
// the parameter type the binding's annotation instantiates — `Box.new[T]`
// gets `T = Wrap[i64]` from `Box[Wrap[i64]]`, so `inner: 1` is an i64. The
// argument was checked before the instantiation was known and defaulted to
// Wrap[i32].

use std.box.Box
use std.rc.Rc

type Wrap[T] { inner: T, tag: i64 }

fn main:
    let bw: Box[Wrap[i64]] = Box.new(Wrap { inner: 1, tag: 33 })
    print(f"{bw.as_ref().tag}")
    print(f"{bw.as_ref().inner}")
    let bi: Box[i64] = Box.new(41)
    print(f"{bi.as_ref()}")
    let ri: Rc[i64] = Rc.new(77)
    print(f"{ri.as_ref()}")
