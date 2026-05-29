//! expect-check-fail: return type mentions Self

trait CloneLike:
    fn clone_like(self: &Self) -> Option[Self]

type Item { value: i32 }

impl CloneLike for Item:
    fn clone_like(self: &Self) -> Option[Self]:
        Some(Item { value: self.value })

fn accept(_c: &dyn CloneLike) -> i32:
    1

fn main:
    let item = Item { value: 3 }
    let _ = accept(&item)
