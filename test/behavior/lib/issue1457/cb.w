// #1457: declares `Item` with the same name as issue1457.ca's, different fields.
pub type Item { s: str, k: i32 }
impl Item:
    pub fn twin_b() -> Self: Self { s: self.s ++ "!", k: self.k + 1 }
    pub fn total() -> i64: self.s.len() as i64 + self.k as i64
pub fn Item.make_b() -> Self: Self { s: "bee".clone(), k: 7 }
pub fn Item.tag() -> str: "b"
pub fn show_b(i: &Item) -> str: f"b {i.s} {i.k}"
pub fn new_b() -> Item: Item.make_b()
pub fn total_b() -> i64: new_b().total()
pub fn tag_b() -> str: Item.tag()
