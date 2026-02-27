// Test: Type aliases
type Int = i32
type Pair = { a: i32, b: i32 }

fn add(p: Pair) -> Int:
    p.a + p.b

fn main -> i32:
    let p = Pair { a: 20, b: 22 }
    if add(p) == 42 then 0 else 1
