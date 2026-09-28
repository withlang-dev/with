//! expect-stdout: 1
//! expect-stdout: 2
//! expect-stdout: 12
//! expect-stdout: 12

// D73 / §4.2 (#1479): an assignment in the tail of a body with no declared
// return type is a statement, and the body returns Unit — through the
// wrappers the tail passes on the way (`unsafe:`, braced `unsafe { }`), as
// for a bare `fn f: x = e`. Sema discarded only the body block's own tail,
// so `fn bump:` below inferred `-> i32` and was refused where `fn() -> Unit`
// is expected (exposed by #1772's fn-type check). Under a declared non-Unit
// return the same tail is the body's value, a read of the place (D60).

var COUNT = 0

fn bump:
    unsafe:
        COUNT = COUNT + 1

fn bump_braced: unsafe { COUNT = COUNT + 1 }

fn bump_ten() -> i32:
    unsafe:
        COUNT = COUNT + 10

fn call_unit(f: fn() -> Unit): f()

fn count() -> i32: unsafe { COUNT }

fn main:
    call_unit(bump)
    print(count())
    call_unit(bump_braced)
    print(count())
    print(bump_ten())
    print(count())
