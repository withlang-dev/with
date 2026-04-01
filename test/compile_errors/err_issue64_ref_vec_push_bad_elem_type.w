//! expect-error: wrong argument type in call to 'Vec.push'

type Inner {
    tags: Vec[i32],
}

fn main:
    var items: Vec[Inner] = Vec.new()
    let borrowed = &mut items
    borrowed.push(1)
