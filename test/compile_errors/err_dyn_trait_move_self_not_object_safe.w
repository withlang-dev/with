//! expect-check-fail: uses consuming receiver

trait Consumable:
    fn consume(move self: Self) -> i32

type Food { value: i32 }

impl Consumable for Food:
    fn consume(move self: Self) -> i32:
        self.value

fn accept(_c: &dyn Consumable) -> i32:
    1

fn main:
    let f = Food { value: 3 }
    let _ = accept(&f)
