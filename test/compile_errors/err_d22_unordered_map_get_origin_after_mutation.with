//! expect-error: cannot mutate `m` while `view` is a live view into it
// D22 cell for an engine facade (§21.1 rule 6): the accessor reaches the
// view through the engine's slot pointer and states `from self`; a
// mutation under the view is refused as HashMap's is.
use std.collections.unordered_map.UnorderedMap
fn main:
    var m: UnorderedMap[i32, i32] = UnorderedMap.new()
    m.insert(1, 86)
    let view: &i32 = m.get(1).unwrap()
    m.remove(1)
    print(*view)
