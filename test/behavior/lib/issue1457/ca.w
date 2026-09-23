// #1457: declares `Item` with the same name as issue1457.cb's, different fields.
pub type Item { x: i64, y: i64 }
impl Item:
    pub fn twin_a() -> Self: Self { x: self.y, y: self.x }
pub fn Item.make_a() -> Self: Self { x: 5, y: 6 }
pub fn show_a(i: &Item) -> str: f"a {i.x} {i.y}"
pub fn new_a() -> Item: Item.make_a()
