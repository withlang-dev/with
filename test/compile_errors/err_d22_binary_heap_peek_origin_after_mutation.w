//! expect-error: cannot mutate `m` while `view` is a live view into it
// D22 cell for an engine facade (§21.1 rule 6): the accessor reaches the
// view through the engine's slot pointer and states `from self`; a
// mutation under the view is refused as HashMap's is.
use std.collections.binary_heap.BinaryHeap
fn main:
    var m: BinaryHeap[i32] = BinaryHeap.new()
    m.push(86)
    let view: &i32 = m.peek().unwrap()
    m.pop()
    print(*view)
