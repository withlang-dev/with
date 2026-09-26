//! expect-stdout: 1 one
//! expect-stdout: 10 ten
//! expect-stdout: 2
//! expect-stdout: 1 one
//! expect-stdout: 10 ten
//! expect-stdout: 3 30
//! expect-stdout: 4 40
//! expect-stdout: 1 one
//! expect-stdout: 10 ten

// #1561 (D44): `for (k, v) in bt` traverses a BTreeMap in key order, binding
// views of Drop-class keys and values and Copy ones by value; the map stays
// whole after the loop, a `&BTreeMap` binding and a generic body traverse
// the same way. The tuple pattern was refused ("tuple pattern requires
// tuple subject") and a generic body's bindings came back undefined.
use std.collections.BTreeMap

fn show[K: Ord, V](m: &BTreeMap[K, V]):
    for (k, v) in m:
        print(f"{k} {v}")

fn main:
    var bt: BTreeMap[i32, str] = BTreeMap.new()
    bt.insert(10, "ten".clone())
    bt.insert(1, "one".clone())
    for (k, v) in bt:
        print(f"{k} {v}")
    print(f"{bt.len()}")
    let r = &bt
    for (k, v) in r:
        print(f"{k} {v}")
    var pod: BTreeMap[i32, i32] = BTreeMap.new()
    pod.insert(4, 40)
    pod.insert(3, 30)
    for (k, v) in pod:
        print(f"{k} {v}")
    show(&bt)
