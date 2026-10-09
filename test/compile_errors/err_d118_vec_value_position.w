//! expect-error: 'Vec' names no type: the growable sequence is 'List' (D118)

// D118: and in value position (`Vec.new()`).
fn main:
    var xs = Vec.new()
    xs.push(1)
    print(xs.len())
