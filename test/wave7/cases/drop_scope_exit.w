extern fn puts(s: *const i8) -> i32

type Handle = { id: i32 }

impl Handle
    fn drop(self: Handle):
        puts("drop_scope_exit")

fn make_handle -> Handle:
    Handle { id: 1 }

fn main -> i32:
    let x = if true then 1 else 2
    let h = make_handle()
    x + h.id - h.id
