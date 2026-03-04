trait Show =
    fn show(self: &Self) -> i32

type Hidden = { v: i32 }

fn require_show[T: Show](value: T) -> i32:
    value.show()

fn main -> i32:
    let x = Hidden { v: 10 }
    require_show(x)
