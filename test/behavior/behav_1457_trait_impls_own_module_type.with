//! expect-stdout: a1
//! expect-stdout: b2
//! expect-stdout: a1!
//! expect-stdout: b2!
//! expect-stdout: a1
//! expect-stdout: b2
//! expect-stdout: 2 4

// #1457, trait half: two modules each declare `Item` and implement the same
// traits for it (§18.1: each module's declarations are its own). The impl
// registry keyed impls by the name, so the second `impl Copy for Item` was
// "duplicate implementation of trait for type"; the trait methods, the
// default method `shout` and the vtables were named and keyed `Item.*`, so
// the second module's would have been the first's.
use issue1457.ta
use issue1457.tb

fn main:
    print(name_a())
    print(name_b())
    print(shout_a())
    print(shout_b())
    print(dyn_a())
    print(dyn_b())
    print(f"{copy_a()} {copy_b()}")
