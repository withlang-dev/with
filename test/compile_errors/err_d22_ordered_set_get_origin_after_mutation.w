//! expect-error: cannot mutate `m` while `view` is a live view into it
// D22 cell for an engine facade (§21.1 rule 6): the accessor reaches the
// view through the engine's slot pointer and states `from self`; a
// mutation under the view is refused as HashMap's is.
use std.collections.ordered_set.OrderedSet
fn main:
    var m: OrderedSet[i32] = OrderedSet.new()
    m.insert(1)
    let view = m.get(1).unwrap()
    m.clear()
    print(*view)
