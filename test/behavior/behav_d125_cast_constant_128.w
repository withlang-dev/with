//! expect-stdout: 1267650600228229401496703205376 340282366920938463463374607431768211455 1024 -1

// D125 (§4.2.1): an untyped constant under a cast has no width limit in the
// rule; this compiler evaluates up to 128 bits, so `(1 << 100) as u128` and
// u128's maximum convert exactly, as do their wraps to narrower types.
fn main:
    let big = (1 << 100) as u128
    let max = 340282366920938463463374607431768211455 as u128
    let shifted = ((1 << 100) >> 90) as u64
    let wrapped = 340282366920938463463374607431768211455 as i64
    print(f"{big} {max} {shifted} {wrapped}")
