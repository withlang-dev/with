//! expect-stdout: 5 Some(7) "rc" [1, 2]
//! expect-stdout: Node { val: 1, next: Some(Node { val: 2, next: None }) }
//! expect-stdout: {"a", "b", "c"}
//! expect-stdout: {1, 10, 2}
//! expect-stdout: {}
//! expect-stdout: Tagged { tags: {"x", "y"}, count: 3 }
//! expect-stdout: [{"q"}]
//! expect-stdout: 0x0
//! expect-stdout: ok

// D71 / §15.4.7 (#1564): the rows Eric added to the `:?` table.
// - `Box[T]`, `Rc[T]`, `Arc[T]`: the value they hold, formatted with `:?`.
//   Rc and Arc printed their handle, `Rc { ptr: 4344693328 }`.
// - `HashSet[T]`: `{elem, elem}`, elements ordered by their Debug text (so
//   10 sorts before 2), at every depth. It printed `HashSet { ptr: ... }`.
// - A raw pointer: its address in hexadecimal. It printed decimal. The
//   address itself differs run to run, so the test checks its shape.

use std.collections
use std.box.Box
use std.rc.Rc
use std.rc.Arc

type Node { val: i32, next: Option[Rc[Node]] }
type Tagged { tags: HashSet[str], count: Rc[i32] }

fn is_hex_digit(c: u8) -> bool: (c >= '0' and c <= '9') or (c >= 'a' and c <= 'f')

fn main:
    let boxed = Box.new(5)
    let counted = Rc.new(Some(7))
    let shared = Arc.new("rc")
    let list = Rc.new([1, 2])
    print(f"{boxed:?} {counted:?} {shared:?} {list:?}")

    let tail = Node { val: 2, next: None }
    let head = Node { val: 1, next: Some(Rc.new(tail)) }
    print(f"{head:?}")

    var words: HashSet[str] = HashSet.new()
    words.insert("b")
    words.insert("c")
    words.insert("a")
    print(f"{words:?}")
    var nums: HashSet[i32] = HashSet.new()
    nums.insert(2)
    nums.insert(10)
    nums.insert(1)
    print(f"{nums:?}")
    let none: HashSet[i32] = HashSet.new()
    print(f"{none:?}")

    var tags: HashSet[str] = HashSet.new()
    tags.insert("y")
    tags.insert("x")
    let tagged = Tagged { tags, count: Rc.new(3) }
    print(f"{tagged:?}")
    var inner: HashSet[str] = HashSet.new()
    inner.insert("q")
    let sets: Vec[HashSet[str]] = [inner]
    print(f"{sets:?}")

    let x = 42
    let text = f"{&raw const x:?}"
    assert(text.len() > 2 and text.starts_with("0x"))
    for i in 2..text.len():
        assert(is_hex_digit(text[i]))
    let nothing: *const i32 = null
    print(f"{nothing:?}")
    print("ok")
