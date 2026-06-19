//! expect-check-fail: use of moved value

trait BoxDynConsumable:
    fn peek(self: &Self) -> i32
    fn consume(move self: Self) -> i32

type BoxDynFood { value: i32 }

impl BoxDynConsumable for BoxDynFood:
    fn peek(self: &Self) -> i32:
        self.value

    fn consume(move self: Self) -> i32:
        self.value

fn main:
    let food: Box[dyn BoxDynConsumable] = Box.new(BoxDynFood { value: 3 })
    let _ = food.consume()
    let _ = food.peek()
