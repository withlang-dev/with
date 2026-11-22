//! expect-check-fail: cannot be read here while the callee is writing into it

// Generic specialization uses the same slice coercion and exclusivity
// contract as an ordinary call; a concrete array is not a second view.
fn change[U](dest: []mut i32, source: []i32, context: &U):
    dest[0] = source[0]
fn main:
    var values: [i32; 2] = [1, 2]
    let context = 0
    change(values, values, context)
