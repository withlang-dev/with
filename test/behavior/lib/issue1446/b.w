// #1446: declares the same type names as issue1446.a with different layouts.
pub type Item { s: str, k: i32 }
pub type Pair { first: Item, n: i32 }
pub enum Shape:
    Circle(label: str)
    Rect(w: i32)
pub enum Kind: i64:
    Lo = 10
    Hi = 20

impl Item:
    pub fn sum_b() -> i64: self.k as i64 + self.s.len()
    pub fn bump_b() -> Self: Item { s: self.s ++ "!", k: self.k + 1 }

pub fn make_b() -> Item: Item { s: "bee".clone(), k: 7 }
pub fn pair_b() -> Pair: Pair { first: make_b(), n: 9 }
pub fn shape_b() -> Shape: Shape.Circle("round".clone())
pub fn area_b(s: &Shape) -> str:
    match s:
        Shape.Circle(l) => l.clone()
        Shape.Rect(w) => f"{w}"
pub fn kind_b() -> Kind: Kind.Lo
pub fn kind_name_b(k: Kind) -> str:
    match k:
        .Lo => "b-lo".clone()
        .Hi => "b-hi".clone()
pub fn show_b(i: &Item) -> Unit: print(f"b {i.s} {i.k} {i.sum_b()}")
pub fn items_b() -> Vec[Item]:
    var v: Vec[Item] = Vec.new()
    v.push(Item { s: "p".clone(), k: 1 })
    v.push(Item { s: "qq".clone(), k: 2 })
    v
pub fn maybe_b(on: bool) -> Option[Item]: if on: Some(make_b()) else: None
