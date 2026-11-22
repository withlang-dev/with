//! expect-stdout: tag=5
// §11.6: the @[sealed] restriction only blocks *external* impls — a sealed
// trait MAY be implemented within its own defining module.
@[sealed]
trait Marker:
    fn tag(self: &Self) -> i32

type Leaf { n: i32 }
impl Marker for Leaf:
    fn tag(self: &Self) -> i32: self.n

fn main:
    let l = Leaf { n: 5 }
    print(f"tag={l.tag()}")
