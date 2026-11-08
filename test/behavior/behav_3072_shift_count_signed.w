//! expect-stdout: 8 4 1024 -2 0
// D197 (§4.2.4): a shift count is any integer type. An `i32` index minted by
// the program counts without a cast; an `i64` count and an `isize` loop
// counter too. The count converts to `u32` with a range check (§4.2.6).
fn bit(slot: i32) -> i64: 1 << slot

fn main:
    let k: i32 = 3
    let wide: i64 = 2
    var acc = 0
    for i in 0..3: acc = acc + (1 << i)
    print(f"{bit(k)} {16 >> wide} {bit(10)} {-8 >> wide} {acc - 7}")
