//! expect-error: expected 'await'

// §4.3d (D80, #1874): lane selection is the method `m.select(a, b)`;
// `select` is only the `select await` keyword (§14.10).
fn main:
    let a = i32x4(1, 2, 3, 4)
    let c = select(a > 2, a, a)
    print(f"{c[0]}")
