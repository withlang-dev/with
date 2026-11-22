//! expect-check-fail: parameter mentions Self outside the receiver

trait Comparable:
    fn compare(self: &Self, other: &Self) -> i32

type Item { value: i32 }

impl Comparable for Item:
    fn compare(self: &Self, other: &Self) -> i32:
        self.value - other.value

fn accept(_c: &dyn Comparable) -> i32:
    1

fn main:
    let item = Item { value: 3 }
    let _ = accept(&item)
