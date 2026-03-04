trait CloneLike =
    fn clone(self: Self) -> Self

fn use_dyn(x: dyn CloneLike) -> i32:
    0

fn main -> i32: 0
