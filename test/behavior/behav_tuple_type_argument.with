//! expect-stdout: ok

// #2565: a tuple type argument spelled at a static call
// (`Deque[(i32, i32)].new()`, `Box[(i32, i32)].new(..)`) is the same type
// as in an annotation: the instance is concrete, its generic methods
// specialize, and a field read through the method's `&T` view types as the
// tuple element.

use std.collections.deque.Deque

pub type Box[T] { v: T }
impl[T] Box[T]:
    pub fn get() -> &T from self: &self.v
pub fn Box.new[T](v: T) -> Box[T]: Box { v: v }

fn boxes():
    let b = Box[(i32, i32)].new((1, 2))
    let v = b.get()
    assert(v.0 == 1 and v.1 == 2)
    let x = v.0 + v.1
    assert(x == 3)
    let nested = Box[(str, (i32, bool))].new(("a", (7, true)))
    assert(nested.get().1.0 == 7 and nested.get().1.1)

fn deques():
    var d = Deque[(i32, i32)].new()
    d.push_back((1, 2))
    d.push_back((3, 4))
    assert(d.get(0).0 == 1 and d.get(1).1 == 4)
    var sum = 0
    var cursor = d.iter()
    while let Some(pair) = cursor.next():
        sum = sum + pair.0 + pair.1
    assert(sum == 10)
    let taken = d.pop_front().unwrap()
    assert(taken.0 == 1 and taken.1 == 2)

fn main:
    boxes()
    deques()
    print("ok")
