// Wave 6: inherent-vs-trait method resolution order.

trait Score =
    fn eval(self: Self) -> i32

type Item = {
    value: i32,
}

impl Score for Item =
    fn eval(self: Item) -> i32:
        self.value + 1

fn Item.eval(self: Item) -> i32:
    self.value + 2

fn main -> i32:
    let it = Item { value: 5 }
    let got = it.eval()
    assert(got == 7)
    got
