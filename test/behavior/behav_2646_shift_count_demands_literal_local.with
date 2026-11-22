//! expect-stdout: 120 86 52 18 | 120 86 52 18 | 86 | 1 2 4
// #2646 (D128), D197: a shift count that reads a literal-typed local — a list
// literal walked by `for`, a range's bounds through arithmetic on the loop
// variable, a plain `let` — converts to `u32` with a range check (§4.2.6);
// each was "shift count must be unsigned integer" before D160, and D160's own
// `u32` demand on the local retired with D197.
fn main:
    let v: i64 = 0x12345678
    var out = ""
    for shift in [0, 8, 16, 24]: out = out ++ f"{(v >> shift) & 255} "
    out = out ++ "| "
    for k in 0..4: out = out ++ f"{(v >> (k * 8)) & 255} "
    let s = 8
    out = out ++ f"| {(v >> s) & 255} | "
    var bits = ""
    for b in 0..3: bits = bits ++ f"{1 << b} "
    print(out ++ bits.trim())
