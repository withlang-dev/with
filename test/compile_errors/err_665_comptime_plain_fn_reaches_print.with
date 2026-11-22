//! expect-check-fail: 'helper' is not comptime-callable: it reaches helper -> print -> with_println_str (an extern)

// #665 (§17.1, D104): the chain through a plain callee names the generic
// function it calls by its declaration. `print` in a checked body resolved
// to its specialization, which has no declaration, and the chain ended
// "print__sema__… (no With body)".
fn helper(n: i32) -> i32:
    print("hi")
    n

comptime fn build(n: i32) -> i32: helper(n) + 1

fn main: print(build(2))
