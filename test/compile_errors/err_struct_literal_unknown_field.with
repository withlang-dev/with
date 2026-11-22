//! expect-check-fail: unknown field 'z' for type 'P'
// §4.3: a struct literal may only initialize fields the struct declares.
type P { x: i32, y: i32 }

fn main:
    let _p = P { x: 1, y: 2, z: 3 }
