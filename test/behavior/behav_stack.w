//! expect-stdout: ok

// Stack[T] over the STC stack (docs/proposals/stdlib_sourcing_plan.md Phase
// 3): push and pop, peek and get observe, traversal bottom to top, the
// word shape for integer scalars, exactly-once drops of values left in a
// dropped stack.

use std.collections.stack.Stack

type Tag { id: i32, slot: *mut i32 }
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn strings():
    var s = Stack[str].new()
    assert(s.is_empty() and s.peek().is_none() and s.pop().is_none())
    s.push("a")
    s.push("b")
    s.push("c")
    assert(s.len() == 3 and *s.peek().unwrap() == "c")
    assert(*s.get(0) == "a" and *s.get(2) == "c")
    // `s[i]` is the element's view (IndexGet, #2560).
    assert(*s[0] == "a" and *s[1] == "b" and *s[2] == "c")
    var cursor = s.iter()
    var seen: List[str] = []
    while let Some(v) = cursor.next(): seen.push(*v)
    assert(seen == ["a", "b", "c"])
    assert(s.pop().unwrap() == "c" and s.pop().unwrap() == "b")
    assert(s.len() == 1 and *s.peek().unwrap() == "a")
    for i in 0..100: s.push(f"{i}")
    assert(s.len() == 101 and *s.peek().unwrap() == "99")
    s.clear()
    assert(s.is_empty())

// The word shape: integer scalars live inline in the engine's array.
fn words():
    var s = Stack[i64].new()
    for i in 0..1000: s.push(i as i64 * 3)
    assert(s.len() == 1000 and *s.peek().unwrap() == 2997 and *s.get(500) == 1500)
    for i in 0..1000: assert(s.pop().unwrap() == (999 - i) as i64 * 3)
    assert(s.is_empty())
    var bytes = Stack[u8].new()
    bytes.push(255)
    bytes.push(1)
    assert(bytes.pop().unwrap() == 1 and bytes.pop().unwrap() == 255 and bytes.is_empty())
    var negatives = Stack[i32].new()
    negatives.push(-7)
    assert(*negatives.peek().unwrap() == -7 and negatives.pop().unwrap() == -7)
    var big = Stack[u64].new()
    big.push(18446744073709551615)
    assert(big.pop().unwrap() == 18446744073709551615)

fn drops():
    var total: i32 = 0
    let slot = &raw mut total
    with 0 as scope:
        var s = Stack[Tag].new()
        for id in [5i32, 2, 8]: s.push(Tag { id: id, slot: slot })
        let top = s.pop().unwrap()
        drop(top)
        assert(total == 8)
    // The two left dropped with the stack: 5 + 2.
    assert(total == 15)

fn main:
    strings()
    words()
    drops()
    print("ok")
