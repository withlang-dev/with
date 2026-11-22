//! expect-stdout: 6 2 3

// A program's own `type T` or `type K` is not what std's `comptime if
// word[T]()` names inside a generic impl: during the comptime transform a
// declaration's type parameters are unbound, and the condition waits for
// the instantiation (the Deque and the B+tree word shapes, D148).
use std.collections.deque.Deque
use std.collections.BTreeMap
use std.collections.BTreeSet

type T { v: i32 }
type K { v: i32 }
type V { v: i32 }

fn main:
    var d = Deque[i32].new()
    d.push_back(4)
    var m = BTreeMap[i32, i32].new()
    m.insert(1, 2)
    var s = BTreeSet[i64].new()
    s.insert(3)
    let t = T { v: 2 }
    let k = K { v: 0 }
    let v = V { v: 1 }
    print(f"{*d.get(0) + t.v} {*m.get(&1).unwrap() + k.v} {s.items()[0] + v.v - 1}")
