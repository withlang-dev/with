//! expect-stdout: 1 7 42
// #1982: a struct literal through a name for a generic struct's instance —
// an alias (std.sync's `AtomicI64 = Atomic[i64]` is written this way) or a
// type parameter instantiated with one — is the base struct's literal typed
// as that instance. It was left untyped and lowered by name; the scalar
// instantiation of the same body is refused (err_1982_*).
use std.sync

type Bx[T] { v: T }
type IB = Bx[i32]

fn mk[T](x: T) -> T: T { v: 7 }

fn main:
    let b = IB { v: 1 }
    let c = mk(Bx { v: 2 })
    var a = atomic_new(40)
    print(f"{b.v} {c.v} {a.add(2)}")
