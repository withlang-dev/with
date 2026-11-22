//! expect-stdout: 10
//! expect-stdout: 10
//! expect-stdout: 2
//! expect-stdout: 10
// D117 (§9.5): a `move fn` declared before its `fn` twin resolves the
// same as the forward order: a place receiver observes, an owned
// receiver takes. Before the fix the later plain spelling collided
// with the move one and a place call consumed the receiver.
pub type Box[T] { items: List[T] }

impl[T] Box[T]:
    pub move fn first() -> Option[T]:
        match move self:
            Box { items: xs } => (move xs).first()

    pub fn first() -> Option[&T]: self.items.first()

fn main:
    var b = Box { items: [10, 20] }
    print(b.first() ?? &-1)
    print(b.first() ?? &-1)
    print(b.items.len())
    print((move b).first() ?? -1)
