extern fn puts(s: *const i8) -> i32

type A = { id: i32 }

impl A
    fn drop(self: A) =
        puts("drop A")

type B = { id: i32 }

impl B
    fn drop(self: B) =
        puts("drop B")

fn main() -> i32 =
    let a = A { id: 1 }
    let b = B { id: 2 }
    a.id + b.id - 3 + 42
