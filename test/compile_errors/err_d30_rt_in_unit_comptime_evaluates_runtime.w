//! expect-check-fail: 'with_println_str' has no With body to evaluate at compile time

// D104 under D30: evaluating a call that reaches the runtime stops at the
// runtime function, as with the object-linked runtime; the evaluator walked
// into its in-unit body and reported the runtime's internals (str_data's
// raw read) instead.
fn shout() -> i32:
    print("loud")
    1

const N = shout()

fn main:
    print(f"{N}")
