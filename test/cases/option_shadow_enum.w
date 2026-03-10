//! expect-stdout: ok
extern fn print(s: str) -> void

// User-defined enum with the same variant names as Option (None, Some).
// This must not interfere with the prelude's VecIter_i32.next which
// returns codegen-internal Option[i32] using .Some(val) and .None.
type MyOption = None | Some(i32)

fn double(x: i32) -> i32:
    x * 2

fn main:
    // Vec.map uses VecIter_i32 internally — tests that Option codegen
    // is not confused by MyOption's None/Some variants.
    var items: Vec[i32] = Vec.new()
    items.push(5)
    items.push(10)
    let doubled = items.map(double)
    assert(doubled.len() == 2)

    // Also test user enum directly
    let x = MyOption.None
    let y = MyOption.Some(42)

    print("ok")
