//! expect-stdout: ok

type Payload {
    values: List[i32],
}

type Bag {
    items: List[Payload],
}

impl Bag:
    mut fn emit(item: Payload) -> Unit:
        self.items.push(move item)

fn transfer(flag: bool) -> i32:
    var bag = Bag { items: List.new() }
    let pending = Payload { values: List.new() }
    pending.values.push(42)
    if flag:
        bag.emit(move pending)
    if bag.items.len() != 1:
        return 1
    if bag.items[0].values[0] != 42:
        return 2
    0

fn main:
    assert(transfer(true) == 0)
    print("ok")
