//! expect-check-fail: Box[str]
//! expect-check-fail: does not implement trait 'Tag'

trait Tag:
    fn tag(move self: Self) -> i32

type Box[T] { value: T }

impl Tag for Box[i32]:
    fn tag(move self: Box[i32]) -> i32:
        self.value

fn need_tag[T: Tag](x: T) -> i32:
    x.tag()

fn main:
    let s: Box[str] = Box { value: "no" }
    need_tag(s)
