//! expect-stdout: ok

trait Tag:
    fn tag(move self: Self) -> i32

type Box[T] { value: T }

impl Tag for Box[i32]:
    fn tag(move self: Box[i32]) -> i32:
        self.value

fn need_tag[T: Tag](x: T) -> i32:
    x.tag()

fn main:
    let b: Box[i32] = Box { value: 7 }
    assert(need_tag(b) == 7)
    print("ok")
