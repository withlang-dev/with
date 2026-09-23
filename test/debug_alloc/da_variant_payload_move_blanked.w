//! expect-debug-alloc: leak count=0
//! expect-stdout: 100
//! expect-stdout: 100
//! expect-stdout: 100
//! expect-stdout: 100
//! expect-stdout: 100
//! expect-stdout: 7

// #1394: a value moved out of an enum variant's payload is reset-on-move
// (§2.5.1): the payload slot is blanked on the moving path, so the enum's
// drop glue frees nothing there. Before, such a move registered no reset,
// and every carrier eliminator that did not hand-roll the subject's
// ownership left the enum drop to free the payload the result owned.
use std.builtins.print_i64

fn numbers() -> Vec[i32]:
    var v: Vec[i32] = Vec.new()
    for i in 0..100: v.push(i)
    v

fn failing() -> Result[i32, Vec[i32]]: Err(numbers())

type Holder { items: Vec[i32], n: i32 }

fn held() -> Option[Holder]: Some(Holder { items: numbers(), n: 7 })

fn main:
    // `map` passes the Err payload through into the new Result.
    match failing().map((x) => x + 1):
        Ok(_) => print_i64(0)
        Err(e) => print_i64(e.len())
    // `ok()`/`err()` move the payload into an Option.
    match failing().err():
        Some(e) => print_i64(e.len())
        None => print_i64(0)
    // `?.` moves a field out of the Some payload.
    let items: Option[Vec[i32]] = held()?.items
    match items:
        Some(v) => print_i64(v.len())
        None => print_i64(0)
    // A failed guard gives the binding back: the next arm binds the same
    // payload, which the guarded arm's binding must not have freed.
    let opt: Option[Vec[i32]] = Some(numbers())
    match opt:
        Some(v) if v.len() > 500 => print_i64(-1)
        Some(v) => print_i64(v.len())
        None => print_i64(0)
    // A guard that fails on a whole-value binding, then a later arm.
    let whole: Option[Vec[i32]] = Some(numbers())
    match whole:
        w if w.is_none() => print_i64(-2)
        Some(v) => print_i64(v.len())
        None => print_i64(0)
    let h = held()
    match h:
        Some(x) if x.n > 10 => print_i64(-3)
        Some(x) => print_i64(x.n)
        None => print_i64(0)
