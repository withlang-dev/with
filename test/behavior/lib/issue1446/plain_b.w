pub type Item { s: str, k: i32 }
pub fn make_b() -> Item: Item { s: "bee".clone(), k: 7 }
pub fn show_b(i: &Item) -> Unit: print(f"b {i.s} {i.k}")
