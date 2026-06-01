//! expect-error: duplicate implementation of trait for type

type DualIter { index: i32 }

impl Iter[i32] for DualIter =
    fn next(mut self: Self) -> Option[i32]:
        .None

impl Iter[str] for DualIter =
    fn next(mut self: Self) -> Option[str]:
        .None

fn main:
    let iter = DualIter { index: 0 }
    for x in iter:
        print(int_to_string(x as i64))
