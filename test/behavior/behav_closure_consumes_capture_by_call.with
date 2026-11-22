//! expect-stdout: 4
//! expect-stdout: 3
//! expect-stdout: 5

// D63 (§12.4): `let c = || take(ys); c()` moves `ys` — creating a closure
// moves nothing; the call moves the capture. Checking the body used to mark
// the outer binding moved at creation, so the first call was reported as a
// second one ("an earlier call already did"), for a bound closure and for a
// closure argument alike.
fn owned_len(s: str) -> i32: s.len() as i32

fn call(f: fn() -> i32) -> i32: f()

fn main:
    let word = "four"
    let c = () => owned_len(word)
    print(c())
    let abc = "abc"
    print(call(() => owned_len(abc)))
    let hello = "hello"
    let unused = () => owned_len(hello)
    print(hello.len())
