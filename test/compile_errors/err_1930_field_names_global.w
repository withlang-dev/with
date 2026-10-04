//! expect-error: bare 'scale' names both a field of the receiver `Model` and the global `scale` (§9.5)

// §9.5 (#1930): a bare name that names both a receiver field and a global
// is a shadowing error.

let scale = 3

type Model {
    scale: i32,
}

impl Model:
    fn scaled(x: i32) -> i32: x * scale

fn main:
    let m = Model { scale: 2 }
    print(f"{m.scaled(5)}")
