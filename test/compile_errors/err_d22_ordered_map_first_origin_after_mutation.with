//! expect-error: cannot mutate `m` while `view` is a live view into it
// D22 cell for an engine facade (§21.1 rule 6): the accessor reaches the
// view through the engine's slot pointer and states `from self`; a
// mutation under the view is refused as HashMap's is.
use std.collections.ordered_map.OrderedMap
fn main:
    var m: OrderedMap[i32, i32] = OrderedMap.new()
    m.insert(1, 86)
    let (k, view) = m.first().unwrap()
    m.remove(1)
    print(*view)
