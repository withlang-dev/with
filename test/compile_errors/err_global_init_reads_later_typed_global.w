//! expect-error: the initializer of global `doubled` reads `twice`, declared after it: a module's initializers run in declaration order (§9.1c)
// §9.1c: an annotated later global has a type, but no value yet either.
let doubled = twice
let twice: i64 = (3 as i64) * 2

fn main:
    print(f"{doubled}")
