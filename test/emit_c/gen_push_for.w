//! expect-stdout: 0
//! expect-stdout: 7
//! expect-stdout: 14
//! expect-stdout: done 21

// #1766, D69 (§13.4): a `for` over a generator passes its body as a closure
// to the generator's `each`; the body captures the loop's outer state by
// place. The issue's repro.
gen fn nums(n: i32) -> i32:
    for i in 0..n:
        yield i * 7

fn main:
    var sum = 0
    for v in nums(3):
        print(v)
        sum += v
    print(f"done {sum}")
