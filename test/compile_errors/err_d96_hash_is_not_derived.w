//! expect-error: `Hash` is not derived: every key is hashed by the compiler
// §11.8 (D96): there is no `Hash` to derive; a key is hashed by the compiler,
// consistently with its `==`.
@[derive(Eq, Hash)]
type Point { x: i32, y: i32 }

fn main:
    let _ = Point { x: 1, y: 2 }
