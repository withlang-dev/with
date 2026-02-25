// Test: Dynamic dispatch with default methods
trait Sized =
    fn size(self: Self) -> i32

type Small = { val: i32 }
type Big = { val: i32 }

impl Sized for Small =
    fn size(self: Small) -> i32 = 1

impl Sized for Big =
    fn size(self: Big) -> i32 = 100

fn measure(obj: dyn Sized) -> i32 =
    obj.size()

fn main() -> i32 =
    let s = Small { val: 0 }
    let b = Big { val: 0 }
    let a = measure(s)
    let c = measure(b)
    if a == 1 and c == 100 then 0 else 1
