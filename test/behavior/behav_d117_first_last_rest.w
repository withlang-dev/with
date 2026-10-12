//! expect-stdout: 1 3 [2, 3]
//! expect-stdout: 1 3 [2, 3]
//! expect-stdout: [1, 2, 3]
//! expect-stdout: none none []
//! expect-stdout: 5050
//! expect-stdout: drop 2
//! expect-stdout: 1
//! expect-stdout: drop 1

// D117 (§9.5, §13.3): `first()`, `last()` and `rest()` are the expression
// forms of `[first, ..rest]`. On a place they observe (`Option[&T]`, a
// `[]T` view); on an owned receiver, a temporary or `(move xs)`, they take
// (`Option[T]`, a `List[T]` sharing the buffer). The receiver's syntax
// selects the form, so a later use of `xs` never changes what a call
// returned, and the owned `rest()` recursion is O(n).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): print(f"drop {self.id}")

fn sum(xs: List[i32]) -> i32:
    match xs.first():
        Some(h) => *h + sum((move xs).rest())
        None => 0

fn main:
    let xs = [1, 2, 3]
    print(f"{xs.first().unwrap()} {xs.last().unwrap()} {xs.rest():?}")
    // the same calls again: the place is untouched
    print(f"{xs.first().unwrap()} {xs.last().unwrap()} {xs.rest():?}")
    print(f"{xs:?}")
    let e: List[i32] = List.new()
    let f = if e.first().is_none(): "none" else: "some"
    let l = if e.last().is_none(): "none" else: "some"
    print(f"{f} {l} {e.rest():?}")
    var big: List[i32] = List.new()
    for i in 1..101: big.push(i)
    print(sum(big))
    // an owned receiver takes: the element comes out, the rest drops
    let t = [Tok { id: 1 }, Tok { id: 2 }].first()
    print(t.unwrap().id)
