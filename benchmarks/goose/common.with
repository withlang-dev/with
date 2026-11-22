// Shared deterministic input stream; identical to Goose bench/goose/rng.goose.
pub fn xs_next(state: u64) -> u64:
    var x = state
    x = x ^ (x << 13)
    x = x ^ (x >> 7)
    x = x ^ (x << 17)
    x

pub fn xs_mod(state: u64, modulus: i64) -> i64:
    (state % (modulus as u64)) as i64
