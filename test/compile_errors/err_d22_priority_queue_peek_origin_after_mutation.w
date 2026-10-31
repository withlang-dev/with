//! expect-error: cannot mutate `m` while `view` is a live view into it
// D22 cell for an engine facade (§21.1 rule 6): the accessor reaches the
// view through the engine's slot pointer and states `from self`; a
// mutation under the view is refused as HashMap's is.
use std.collections.priority_queue.PriorityQueue
fn main:
    var m: PriorityQueue[i32] = PriorityQueue.new()
    m.push(86)
    let view: &i32 = m.peek().unwrap()
    m.pop()
    print(*view)
