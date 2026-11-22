//! expect-stdout: 4 none 7

// #3360: an inherited default method's body is checked by the function-body
// check, so its tail is under the declared return as any function's is: a
// `T` tail under `Option[T]` is `Some` (§4.9a), on every path.
trait Sink:
    fn tag(self: &Self) -> i32
    fn above(self: &Self, n: i32) -> Option[i32]:
        if n < 0: return None
        self.tag() + n
    fn pick(self: &Self, n: i32) -> Option[i32]:
        if n > 5: n else: self.tag() + 6

type S { t: i32 }
impl Sink for S:
    fn tag(self: &Self) -> i32: self.t

fn show(v: Option[i32]) -> str:
    match v:
        Some(n) => f"{n}"
        None => "none"

fn main:
    let s = S { t: 1 }
    print(show(s.above(3)) ++ " " ++ show(s.above(-1)) ++ " " ++ show(s.pick(0)))
