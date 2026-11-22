//! expect-stdout: 6 10
//! expect-stdout: 15 5
//! expect-stdout: 1 4 2 5 3 6
//! expect-stdout: 9 3

// D119 Amendment 1 (§4.3a, #2311): an array length is a generic parameter,
// bound from the argument's array type by the mechanism `Vector[T, N]`
// uses (§4.3d) — one length, the same length twice, and two lengths of a
// multidimensional array each monomorphize per length.

fn total[N](xs: [i32; N]) -> i32:
    var s = 0
    for x in xs: s = s + x
    s

fn trace[N](m: [i32; N, N]) -> i32:
    var s = 0
    for i in 0..m.len(): s = s + m[i][i]
    s

fn transpose[R, C](m: [i32; R, C]) -> [i32; C, R]:
    var out: [i32; C, R] = [0; C, R]
    for r in 0..m.len():
        for c in 0..m[0].len():
            out[c][r] = m[r][c]
    out

fn first[N](xs: [i32; N]) -> i32: xs[0]

fn main:
    let a: [i32; 3] = [1, 2, 3]
    let b: [i32; 4] = [1, 2, 3, 4]
    print(f"{total(a)} {total(b)}")
    let sq: [i32; 3, 3] = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    let one: [i32; 1, 1] = [[5]]
    print(f"{trace(sq)} {trace(one)}")
    let m: [i32; 2, 3] = [[1, 2, 3], [4, 5, 6]]
    let t = transpose(m)
    print(f"{t[0][0]} {t[0][1]} {t[1][0]} {t[1][1]} {t[2][0]} {t[2][1]}")
    // A bracket literal takes no generic array demand yet (#2379); the
    // arguments are named arrays, as every call above.
    let nine: [i32; 3] = [9, 8, 7]
    let three: [i32; 1] = [3]
    print(f"{first(nine)} {total(three)}")
