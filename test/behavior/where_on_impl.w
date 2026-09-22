//! expect-stdout: ok

trait Describable:
    fn describe(self: &Self) -> str

trait Showable:
    fn show(self: &Self) -> str

type Pair { a: i32, b: i32 }

impl Describable for Pair:
    fn describe(self: &Self) -> str:
        "pair"

// where clause on impl (parsed, not yet enforced)
impl Showable for Pair where Pair: Describable:
    fn show(self: &Self) -> str:
        self.describe()

fn main:
    let p = Pair { a: 1, b: 2 }
    assert(p.show() == "pair")
    print("ok")
