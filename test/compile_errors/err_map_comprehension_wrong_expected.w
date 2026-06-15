//! expect-error: map comprehension requires HashMap or BTreeMap expected type

fn main:
    let _bad: Vec[(i32, i32)] = [x: x for x in 0..3]
