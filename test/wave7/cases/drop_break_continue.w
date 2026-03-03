extern fn puts(s: *const i8) -> i32

type Handle = { id: i32 }

impl Handle
    fn drop(self: Handle):
        puts("drop_break_continue")

fn make_handle -> Handle:
    Handle { id: 3 }

fn main -> i32:
    var n = 0
    loop:
        let h = make_handle()
        n = n + 1
        if n > 1:
            break n
        continue
