//! expect-check-fail: cannot format a value of type 'fn(i32) -> i32' with :? — §15.4.7 gives it no Debug form

// D71 / §15.4.7 (#1564): Debug is recursive, so an enum payload with no
// Debug form leaves the enum without one: the error names the payload's
// type at the `:?`.

enum Step:
    Apply(fn(i32) -> i32)
    Stop

fn twice(x: i32): x * 2

fn main:
    let s = Step.Apply(twice)
    print(f"{s:?}")
