//! expect-stdout: ok

// D96: `std.hash.hash_of` is the hash a map gives a key. Equal keys hash
// equal; a key projection hashes what it projects.
use std.hash

type Tag { name: str }
impl Key for Tag:
    fn key(): self.name.to_lower()

type Point { x: i32, y: i32 }

fn main:
    let a: i32 = 42
    assert(hash_of(&a) == hash_of(&a))
    let b: i32 = 43
    assert(hash_of(&a) != hash_of(&b))

    let s1 = "hello"
    let s2 = "hel" ++ "lo"
    assert(hash_of(&s1) == hash_of(&s2))
    assert(hash_of(&s1) != hash_of(&"world"))

    let p = Point { x: 1, y: 2 }
    let q = Point { x: 1, y: 2 }
    assert(hash_of(&p) == hash_of(&q))

    let up = Tag { name: "Red" }
    let low = Tag { name: "red" }
    assert(up == low)
    assert(hash_of(&up) == hash_of(&low))

    let v: Vec[i32] = [1, 2, 3]
    let w: Vec[i32] = [1, 2, 3]
    assert(hash_of(&v) == hash_of(&w))
    print("ok")
