//! expect-error: element comprehension cannot target a map; use [key: value for ...] form

fn main:
    let _bad: HashMap[i32, i32] = [x for x in 0..3]
