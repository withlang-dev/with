//! expect-check-fail: return type mentions Self

trait Transformer:
    type Output
    fn transform(self: &Self) -> Self.Output

type Item { value: i32 }

impl Transformer for Item:
    type Output = i32

    fn transform(self: &Self) -> Self.Output:
        self.value

fn accept(_c: &dyn Transformer) -> i32:
    1

fn main:
    let item = Item { value: 3 }
    let _ = accept(&item)
