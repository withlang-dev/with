//! expect-stdout: 7 -9223372036854775808 14
// A global's initializer may name a constant declared after it, as a
// modeled C header's `#define QUAD_MIN LLONG_MIN` does before `LLONG_MIN`:
// the later global's initializer is checked first, so it has a type. An
// untyped one left the reader untyped ("no initializer codegen can lower").
let alias = later
let quad_min = llong_min
let twice = alias * 2
let later = 7
let llong_min: i64 = -9223372036854775807 - 1

fn main:
    print(f"{alias} {quad_min} {twice}")
