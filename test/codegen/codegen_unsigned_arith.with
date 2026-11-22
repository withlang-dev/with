//! expect-stdout: ok

fn u8_div(x: u8, y: u8) -> u8:
    x / y

fn u8_mod(x: u8, y: u8) -> u8:
    x % y

fn u8_gt(x: u8, y: u8) -> bool:
    x > y

fn u8_lt(x: u8, y: u8) -> bool:
    x < y

fn u8_gte(x: u8, y: u8) -> bool:
    x >= y

fn u8_lte(x: u8, y: u8) -> bool:
    x <= y

fn main:
    // unsigned division: 255 / 3 = 85 (not -1/3 = 0)
    assert(u8_div(255, 3) == 85)
    // unsigned modulo: 255 % 10 = 5
    assert(u8_mod(255, 10) == 5)

    // unsigned comparisons
    assert(u8_gt(200, 100))
    assert(u8_lt(100, 200))
    assert(u8_gte(200, 200))
    assert(u8_lte(100, 100))

    print("ok")
