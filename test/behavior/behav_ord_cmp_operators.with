//! expect-stdout: ok

// §11.7: Ord.cmp(&other) backs <, <=, >, >= and Eq.eq(&other) backs ==, !=
// on owned values and on views alike; a fixed-name method overrides its
// operator; a reversed selection (the primitive lives on the right operand's
// type) flips the ordering's sign.

use std.builtins.print_i32

type Tag { id: i32, pad: i64 }
impl Ord for Tag:
    fn cmp(other: &Tag) -> i32:
        if self.id < other.id: -1 else if self.id > other.id: 1 else: 0
impl Eq for Tag:
    fn eq(other: &Tag) -> bool: self.id == other.id

// gt is overridden to count its calls; the other three still derive.
var gt_calls = 0
type Counted { id: i32 }
impl Ord for Counted:
    fn cmp(other: &Counted) -> i32:
        if self.id < other.id: -1 else if self.id > other.id: 1 else: 0
impl Counted:
    fn gt(other: &Counted) -> bool:
        gt_calls = gt_calls + 1
        self.id > other.id

fn order[T: Ord](a: &T, b: &T) -> i32: if a < b: -1 else if a > b: 1 else: 0

fn main:
    let x = Tag { id: 20, pad: 0 }
    let y = Tag { id: 10, pad: 0 }
    // declaration order is x then y: address order would say x < y
    assert(not (x < y) and x > y and x >= y and not (x <= y))
    assert(y < x and y <= x and not (y > x))
    assert(x == x and x != y and not (x == y) and not (x != x))
    assert(order(&x, &y) == 1 and order(&y, &x) == -1 and order(&x, &x) == 0)
    assert(order(&3, &4) == -1 and order(&"b", &"a") == 1)
    let c = Counted { id: 1 }
    let d = Counted { id: 2 }
    assert(not (c > d) and d > c and c < d and d >= c and c <= d)
    assert(gt_calls == 2)
    print("ok")
