//! expect-check-fail: expected ':' or '{'

trait Show:
    fn show(self: &Self) -> str

type Item {}

impl Show for Item =
    fn show(self: Item) -> str:
        "item"
