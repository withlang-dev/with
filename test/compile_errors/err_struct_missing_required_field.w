//! expect-error: missing field 'name' in struct literal

type Required {
    name: str,
    age: i32 = 0,
}

fn main:
    let _ = Required { age: 25 }
