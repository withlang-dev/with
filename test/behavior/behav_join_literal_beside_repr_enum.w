//! expect-stdout: 3 1

// An untyped literal takes a numeric peer's type (§4.2.1), and a `repr`
// enum is not a number it can become: `[0, K.A, K.B]` is an array of
// integers, as it was before the peer rule, and the loop variable is a
// Copy isize (the compiler's own MirValidationTests iterate exactly this).
enum K: i32:
    A = 1
    B = 2

fn main:
    var kinds: List[isize] = List.new()
    var ones = 0
    for k in [0, K.A, K.B]:
        kinds.push(k)
        if k == K.A: ones = ones + 1
    print(f"{kinds.len()} {ones}")
