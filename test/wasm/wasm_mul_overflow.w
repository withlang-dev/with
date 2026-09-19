//! expect-stdout: p=1000000000000000000
//! expect-stdout: q=-6148914691236517204
//! expect-stdout: wide_ok=true
//! expect-exit: 134

// Every checked 64-bit multiply and every i128 multiply lowers to
// compiler-rt's __multi3 on wasm; rt/wasm.w provides it. The last line
// overflows on purpose and must panic (exit 134, as on the native targets).
fn main:
    let a: i64 = 1000000000
    let b: i64 = 1000000000
    print(f"p={a * b}")
    let c: i64 = 3074457345618258602
    print(f"q={c *% 2 *% -1}")
    let w: i128 = 9223372036854775808
    let ww = w * w
    let expected: i128 = 85070591730234615865843651857942052864
    print(f"wide_ok={ww == expected}")
    var big: i64 = 4611686018427387904
    big = big * 2
    print(f"unreachable {big}")
