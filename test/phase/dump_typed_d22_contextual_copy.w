//! args: --dump-typed
//! expect-check-stdout: typed contextual-copy-adjustments=40
//! expect-check-stdout: bind view: &i32
//! expect-check-stdout: bind forwarded: Option[&i32]
//! expect-check-stdout: bind forwarded_view: &i32
//! expect-check-stdout: bind patterned: &i32
//! expect-check-stdout: bind tried: &i32
//! expect-check-stdout: bind exact_dispatch: i32
//! expect-check-stdout: bind generic_argument: i32
//! expect-check-stdout: bind closure_value: i32
//! expect-check-stdout: bind snapshot: i32
//! expect-check-stdout: bind widened: i64
//! expect-check-stdout: exact=&i32 owned=i32 target=i64 post=i64
//! expect-check-stdout: bind meter_view: &Meter
//! expect-check-stdout: exact=&Meter owned=Meter target=Meter post=identity
//! expect-check-stdout-not: bind view: i32
//! expect-check-stdout-not: bind meter_view: Meter
// The count includes the prelude: five of them are std.collections' D61 map
// formatter (debug_entry_order/debug_entry_before), where `order[a]`,
// `order[b]` and `scratch[k]` — `&i64` element places (D27) — meet an
// owned `i64` demand (an i64 parameter, an i64 element store) and take the
// same contextual Copy this fixture pins for `snapshot`. The rule did not
// move; the prelude gained five sites.


// D22 Stage 2 is intentionally check-only. It proves exact carrier/projection
// types and one Sema-owned adjustment for every independently resolved scalar
// demand without requiring the Stage 5 MIR materialization implementation.
use std.collections.HashMap
type Snapshot { value: i32 }
type Meter { value: i32 }
enum Wrapped:
    Value(i32)

impl Copy for Meter

impl Meter:
    move fn next(): self.value + 1

fn take_owned(value: i32) -> i32: value

// Exact structural overload selection precedes contextual materialization.
fn resolve_exact[T](value: &T) -> i32: 1
fn resolve_exact[T](value: T) -> i64: 2

fn take_generic_owned[T](value: i32, marker: T) -> i32: value

fn call_captured_view(f: fn() -> &i32) -> i32:
    take_owned(f())

fn call_owned_closure(f: fn() -> i32) -> i32: f()

fn forward[T](carrier: Option[&T]): carrier

fn inferred_view(value: &i32):
    value

fn pattern_view(carrier: Option[&i32]):
    match carrier:
        Some(value) => value
        None => panic("missing pattern value")

fn try_view(carrier: Option[&i32]) -> Option[&i32]:
    let value = carrier?
    Some(value)

fn return_owned(value: &i32) -> i32: value

fn explicit_return_owned(value: &i32) -> i32:
    return value

gen fn yield_owned(value: &i32) -> i32:
    yield value

fn main:
    let value = 120
    let carrier1: Option[&i32] = Some(&value)
    let view = carrier1.unwrap()
    let carrier2: Option[&i32] = Some(&value)
    let expected_view = carrier2.expect("present")
    let result_carrier: Result[&i32, str] = Ok(&value)
    let result_view = result_carrier.unwrap()
    let result_carrier2: Result[&i32, str] = Ok(&value)
    let result_expected_view = result_carrier2.expect("present")
    let carrier3: Option[&i32] = Some(&value)
    let forwarded = forward(carrier3)
    let forwarded_view = forwarded.unwrap()
    let inferred = inferred_view(view)
    let carrier4: Option[&i32] = Some(&value)
    let patterned = pattern_view(carrier4)
    let carrier5: Option[&i32] = Some(&value)
    let tried = try_view(carrier5).unwrap()
    let captured = call_captured_view(() => view)
    let closure_value = call_owned_closure(() => view)
    let exact_dispatch = resolve_exact(view)
    let generic_argument = take_generic_owned(view, true)

    let snapshot: i32 = view
    var assigned: i32 = 0
    assigned = view
    let widened: i64 = view
    let casted = view as i64
    let returned = return_owned(view)
    let explicitly_returned = explicit_return_owned(view)
    let argument = take_owned(view)
    let record = Snapshot { value: view }
    let tuple: (i32, i32) = (view, 120)
    let array: [1]i32 = [view]
    let collection: Vec[i32] = [view]
    let direct_collection = Vec[i32][view]
    let reference_values: [1]&i32 = [view]
    let comprehended: Vec[i32] = [item for item in reference_values]
    let reference_pairs: [1](&i32, &i32) = [(view, view)]
    let comprehended_map: HashMap[i32, i32] = [key: item for (key, item) in reference_pairs]
    let wrapped: Wrapped = Wrapped.Value(view)
    let owned_carrier: Option[i32] = Some(view)
    let operated = view + 1
    let compared = view == 120

    let meter = Meter { value: 9 }
    let meter_carrier: Option[&Meter] = Some(&meter)
    let meter_view = meter_carrier.unwrap()
    let method_receiver = meter_view.next()

    // Exact references remain reusable after each recorded materialization.
    let still_view: &i32 = view
    let exact_checks: [8]&i32 = [expected_view, result_view, result_expected_view, forwarded_view, inferred, patterned, tried, still_view]
    assert(exact_checks.len() == 8)
    assert(snapshot + assigned + returned + explicitly_returned + argument == 600)
    assert(widened == 120)
    assert(casted == 120)
    assert(record.value == 120)
    assert(tuple.0 == 120)
    assert(array[0] == 120)
    assert(collection.get(0) == 120)
    assert(direct_collection.get(0) == 120)
    assert(comprehended.get(0) == 120)
    assert(comprehended_map.get(120).unwrap() == 120)
    match wrapped:
        Value(inner) => assert(inner == 120)
    assert(owned_carrier.unwrap() == 120)
    assert(operated == 121)
    assert(compared)
    assert(method_receiver == 10)
    assert(captured == 120)
    assert(closure_value == 120)
    assert(exact_dispatch == 1)
    assert(generic_argument == 120)
