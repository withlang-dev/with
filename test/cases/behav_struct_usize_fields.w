type Shape = {
    width: usize,
    offset: isize,
}

fn main:
    let shape = Shape {
        width: 7,
        offset: 3,
    }
    assert(shape.width == 7)
    assert(shape.offset == 3)
