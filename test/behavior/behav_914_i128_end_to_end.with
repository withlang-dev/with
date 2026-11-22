//! expect-stdout: 170141183460469231731687303715884105727
//! expect-stdout: ok

// #914: i128/u128 first-class end to end. The `>> 100` discriminators pin
// the value layers independently of the print path (a formatting defect
// once masqueraded as a literal wrap); the prints pin Display and the
// f-string at full width; the parses round-trip both.
use std.string.parse_i128
use std.string.parse_u128

fn main:
    let max: i128 = 170141183460469231731687303715884105727
    let min: i128 = -170141183460469231731687303715884105728
    let umax: u128 = 340282366920938463463374607431768211455

    // Layer discriminators: computation at full width, no print involved.
    assert((max >> 100) as i64 == 134217727)
    assert((umax >> 100) as i64 == 268435455)
    assert((min >> 127) as i64 == -1)
    let pow100: i128 = 1267650600228229401496703205376
    assert((pow100 >> 90) as i64 == 1024)

    // Signed div/mod sign matrix (truncation toward zero, as at 64 bits).
    assert(-7i128 / 2 == -3 and -7i128 % 2 == -1)
    assert(7i128 / -2 == -3 and 7i128 % -2 == 1)
    assert(pow100 / 1125899906842624 == 1125899906842624)

    // Display and Debug reach i128/u128 like every other width.
    assert(f"{max}" == "170141183460469231731687303715884105727")
    assert(f"{min}" == "-170141183460469231731687303715884105728")
    assert(f"{umax}" == "340282366920938463463374607431768211455")
    assert(max.to_str() == "170141183460469231731687303715884105727")
    assert(min.to_string() == "-170141183460469231731687303715884105728")
    assert(f"{umax:?}" == "340282366920938463463374607431768211455")

    // Eq, Ord, Default, Clone at 128 bits.
    assert(max.eq(max) and not max.eq(min))
    assert(min.cmp(max) < 0 and umax.cmp(umax) == 0)
    assert(i128.default() == 0 and u128.default() == 0)
    assert(max.clone() == max)

    // Parse: boundaries, sign, the string_to_int stopping rule, round-trip.
    assert(parse_i128("170141183460469231731687303715884105727") == max)
    assert(parse_i128("-170141183460469231731687303715884105728") == min)
    assert(parse_u128("340282366920938463463374607431768211455") == umax)
    assert(parse_i128("+42") == 42 and parse_i128("12x9") == 12)
    assert(parse_i128("") == 0 and parse_u128("-5") == 0)
    let x: i128 = -123456789012345678901234567890
    assert(parse_i128(f"{x}") == x)
    assert(parse_u128(f"{umax - 1}") == umax - 1)

    print(max)
    print("ok")
