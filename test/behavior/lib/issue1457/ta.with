// #1457: `Item` with a trait impl, a default method and `Copy`; issue1457.tb
// declares its own `Item` with the same impls.
use issue1457.named
use std.box.Box
pub type Item { x: i64 }
impl Copy for Item
impl Named for Item:
    fn name(self: &Self) -> str: f"a{self.x}"
pub fn new_a() -> Item: Item { x: 1 }
pub fn name_a() -> str: new_a().name()
pub fn shout_a() -> str: new_a().shout()
pub fn dyn_a() -> str:
    let b: Box[dyn Named] = Box.new(new_a())
    b.name()
pub fn copy_a() -> i64:
    let a = new_a()
    let b = a
    a.x + b.x
