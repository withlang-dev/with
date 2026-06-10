//! expect-stdout: ok

trait Source[T]:
    fn next(self) -> Option[T]

type NumSource {}

impl Source[i32] for NumSource:    fn next(self:
    NumSource) -> Option[i32]:
        Some(7)

fn main:
    let src = NumSource{}
    assert(src.next().unwrap() == 7)
    print("ok")
