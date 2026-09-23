// #1446: declares the same type names as issue1446.b with different layouts.
pub type Item { x: i64, y: i64 }
pub type Pair { first: Item, n: i32 }
pub enum Shape:
    Circle(r: i64)
    Rect(w: i64, h: i64)
pub enum Kind: u8:
    Lo = 1
    Hi = 2

impl Item:
    pub fn sum_a() -> i64: self.x + self.y
    pub fn swap_a() -> Self: Item { x: self.y, y: self.x }

pub fn make_a() -> Item: Item { x: 1111111111111, y: 2222222222222 }
pub fn pair_a() -> Pair: Pair { first: make_a(), n: 5 }
pub fn shape_a() -> Shape: Shape.Rect(3, 4)
pub fn area_a(s: &Shape) -> i64:
    match s:
        Shape.Circle(r) => r * r * 3
        Shape.Rect(w, h) => w * h
pub fn kind_a() -> Kind: Kind.Hi
pub fn kind_name_a(k: Kind) -> str:
    match k:
        .Lo => "a-lo".clone()
        .Hi => "a-hi".clone()
pub fn show_a(i: &Item) -> Unit: print(f"a {i.x} {i.y} {i.sum_a()}")
pub fn items_a() -> Vec[Item]:
    var v: Vec[Item] = Vec.new()
    v.push(Item { x: 1, y: 2 })
    v.push(Item { x: 3, y: 4 })
    v
pub fn maybe_a(on: bool) -> Option[Item]: if on: Some(make_a()) else: None
