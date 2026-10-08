//! expect-stdout: 2 pq
//! expect-stdout: 3 6
//! expect-stdout: 2 true
//! expect-stdout: 2 3
// #1739 (§4.3c, §5): an unannotated generic struct literal whose field is
// declared `Vec[T]` (or a set or map) takes its type argument from the
// field's literal. The literal was typed with no expectation, as the
// default fixed array `[str; 2]`, which binds nothing against `Vec[T]`, and
// every method call then failed "cannot infer generic method type
// parameter 'T'". The destination names the collection; the elements
// decide T (the same rule as `let v: Vec[str] = ["p", "q"]`). A generic
// fn's `Vec[T]` parameter is the same destination.
use std.collections.{BTreeMap}

type Stack[T] { items: Vec[T] }
impl[T] Stack[T]:
    fn count() -> i32: self.items.len() as i32
    fn first() -> &T: self.items[0]

type Tally[K, V] { seen: BTreeMap[K, V], total: i64 }
impl[K, V] Tally[K, V]:
    fn size() -> i64: self.seen.len()

fn count_all[T](xs: Vec[T]) -> i64: xs.len()

fn main:
    let st = Stack { items: ["p", "q"] }
    print(f"{st.count()} {st.first()}{st.items[1]}")
    let nums = Stack { items: [1, 2, 3] }
    var sum = 0
    for n in nums.items: sum = sum + n
    print(f"{nums.count()} {sum}")
    let t = Tally { seen: [2: "b", 1: "a"], total: 0 }
    print(f"{t.size()} {t.seen.get(1).unwrap() == \"a\"}")
    print(f"{count_all([\"a\", \"b\"])} {[1, 2, 3] |> count_all()}")
