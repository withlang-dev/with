//! check-only

// Behavior test: function composition operators (spec SS9.6)
// TODO: >> (forward compose) and << (backward compose) not yet implemented.
// >> and << are currently used for bit shift only.

fn main:
    // Bit shift works
    let x = 1 << 3
    assert(x == 8)
    let y = 16 >> 2
    assert(y == 4)
