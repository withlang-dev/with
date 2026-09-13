//! expect-error: operator '<' on views of Tag needs a 'lt' method on Tag

// #1137: ordering two views of a type that has no `lt` used to fall
// through as a pointer comparison of the two references.
type Tag { id: i32, pad: i64 }
impl Ord for Tag:
    fn cmp(other: Tag) -> i32:
        if self.id < other.id: -1 else if self.id > other.id: 1 else: 0

fn first(a: &Tag, b: &Tag) -> bool: a < b

fn main:
    let x = Tag { id: 20, pad: 0 }
    let y = Tag { id: 10, pad: 0 }
    assert(not first(&x, &y))
