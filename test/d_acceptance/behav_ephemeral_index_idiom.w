//! expect-stdout: 20
// §5.1 (#625): the sanctioned idiom — store indices into the owning collection
// rather than ephemeral borrows.
fn main:
    var v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    let idx = 1
    print_i32(v[idx])
