//! expect-stdout: 42 42 7 5 255

// Law 1, D126: a closure parameter no annotation, expected function type or
// partial application types is an integer at the type its uses agree on —
// a demand in its body (`take(x)` at `u8`), or the function type its value
// is passed at (`apply(f, 21)` at `fn(i32) -> i32`) — and the documented
// isize where nothing demands one. It was `i32` whatever the uses said.
fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)
fn take(v: u8) -> u8: v

fn main:
    let doubled = x => x * 2
    let by_arg = apply(doubled, 21)
    let free = x => x * 2
    let by_body = x => take(x)
    let pair = (a, b) => a + b
    let wide = x => x
    print(f"{by_arg} {free(21)} {by_body(7)} {pair(2, 3)} {wide(255)}")
