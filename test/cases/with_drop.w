extern fn puts(s: *const i8) -> i32

type Handle = { id: i32 }

impl Handle
    fn drop(self: Handle) =
        puts("handle dropped")

fn make_handle() -> Handle = Handle { id: 42 }

fn main() -> i32 =
    let result = with make_handle() as h:
        h.id
    assert(result == 42)
    0
