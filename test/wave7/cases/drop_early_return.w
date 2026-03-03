extern fn puts(s: *const i8) -> i32

type Handle = { id: i32 }

impl Handle
    fn drop(self: Handle):
        puts("drop_early_return")

fn make_handle -> Handle:
    Handle { id: 7 }

fn inner(flag: bool) -> i32:
    let h = make_handle()
    if flag:
        return 11
    h.id

fn main -> i32:
    inner(true)
