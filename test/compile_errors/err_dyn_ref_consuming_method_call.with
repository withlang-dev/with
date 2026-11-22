//! expect-check-fail: consuming dyn trait method requires a Box[dyn Trait] receiver

trait Consumable:
    fn peek(self: &Self) -> i32
    fn consume(move self: Self) -> i32

type Food { value: i32 }

impl Consumable for Food:
    fn peek(self: &Self) -> i32:
        self.value

    fn consume(move self: Self) -> i32:
        self.value

fn consume_dyn(c: &dyn Consumable) -> i32:
    c.consume()

fn main:
    let f = Food { value: 3 }
    let _ = consume_dyn(&f)
