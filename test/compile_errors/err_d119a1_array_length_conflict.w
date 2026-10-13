//! expect-error: cannot infer one length for 'N': saw 2 and 3

// D119 Amendment 1 (#2311): `[T; N, N]` binds N from each dimension of the
// argument; a non-square argument binds it twice, differently.

fn trace[N](m: [i32; N, N]) -> i32: m[0][0]

fn main:
    let m: [i32; 2, 3] = [[1, 2, 3], [4, 5, 6]]
    print(trace(m))
