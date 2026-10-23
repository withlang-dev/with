//! expect-error: cannot mutate `m` while `view` is a live view into it
// D22 cell for an engine facade (§21.1 rule 6): the accessor reaches the
// view through the engine's slot pointer and states `from self`; a
// mutation under the view is refused as HashMap's is.
use std.collections.deque.Deque
fn main:
    var m: Deque[i32] = Deque.new()
    m.push_back(86)
    let view = m.front().unwrap()
    m.clear()
    print(*view)
