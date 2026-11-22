// #1457: `Item` with a trait impl, a default method and `Copy`; issue1457.ta
// declares its own `Item` with the same impls.
use issue1457.named
use std.box.Box
pub type Item { y: i32 }
impl Copy for Item
impl Named for Item:
    fn name(self: &Self) -> str: f"b{self.y}"
pub fn new_b() -> Item: Item { y: 2 }
pub fn name_b() -> str: new_b().name()
pub fn shout_b() -> str: new_b().shout()
pub fn dyn_b() -> str:
    let b: Box[dyn Named] = Box.new(new_b())
    b.name()
pub fn copy_b() -> i32:
    let a = new_b()
    let b = a
    a.y + b.y
