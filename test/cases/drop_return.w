extern fn puts(s: *const i8) -> i32

type Guard = { id: i32 }

impl Guard
    fn drop(self: Guard) =
        puts("guard dropped")

fn early() -> i32 =
    let g = Guard { id: 1 }
    return 42

fn main() -> i32 =
    early()
