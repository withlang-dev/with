//! expect-stdout: 91
//! expect-stdout: ok

// D189 (§14.11): tuple `.await` has no arity limit; thirteen tasks join as
// two do.

async fn v(n: i32) -> i32: n

fn main:
    let (a, b, c, d, e, f, g, h, i, j, k, l, m) = (v(1), v(2), v(3), v(4), v(5), v(6), v(7), v(8), v(9), v(10), v(11), v(12), v(13)).await
    print(a + b + c + d + e + f + g + h + i + j + k + l + m)
    print("ok")
