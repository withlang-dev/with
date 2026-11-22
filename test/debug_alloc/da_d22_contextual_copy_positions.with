//! expect-debug-alloc: leak count=0
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 5
// required-verdict: compile-and-run under `--debug-alloc`
// exact-type: inferred `view` is `&i32`; every annotated/resolved demand produces its declared owned type
// expected-diagnostic: none
// origin-set: `view` has `{map}`; each contextual Copy result has `{}`
// drop-behavior: each pointee is copied once per demand; map storage drops once; leak count=0

use std.collections.HashMap
type Snapshot { value: i32 }
type Meter { value: i32 }
enum Wrapped:
    Value(i32)

impl Copy for Meter

impl Meter:
    move fn next(): self.value + 1

fn take_owned(value: i32): value + 1

fn return_owned(map: &HashMap[i32, i32]) -> i32:
    map.get(1).unwrap()

fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 70)

    // Inference preserves &i32. Each derived binding below has a separate,
    // independently-established owned demand and therefore copies the pointee.
    let view = map.get(1).unwrap()
    let binding: i32 = view
    var assigned: i32 = 0
    assigned = view
    let widened: i64 = view
    let argument = take_owned(view)
    let returned = return_owned(&map)
    let record = Snapshot { value: view }
    let tuple: (i32, i32) = (view, 71)
    let wrapped: Wrapped = Wrapped.Value(view)
    let operated = view + 2
    let compared = view == 70
    let casted = view as i64
    let formatted = f"{if true: view else: 0}"

    map.clear()
    assert(binding == 70)
    assert(assigned == 70)
    assert(widened == 70)
    assert(argument == 71)
    assert(returned == 70)
    assert(record.value == 70)
    assert(tuple.0 == 70)
    assert(tuple.1 == 71)
    match wrapped:
        Value(value) => assert(value == 70)
    assert(operated == 72)
    assert(compared)
    assert(casted == 70)
    assert(formatted == "70")

    var meters: HashMap[i32, Meter] = HashMap.new()
    meters.insert(1, Meter { value: 80 })
    let meter_view = meters.get(1).unwrap()
    let method_receiver = meter_view.next()
    meters.clear()
    assert(method_receiver == 81)
