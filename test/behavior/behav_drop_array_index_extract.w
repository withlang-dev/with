//! expect-stdout: ok

// #605 + #606: extracting array elements by index (`a[0]`, `a[1]`) moves them out
// of the source array. The source must be consumed so its element-drop does not
// also free the extracted values. Without the consume, `a` and the extracted
// bindings both drop -> count 4 (double-free).

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn run(slot: *mut i32):
    let a = [W { slot: slot }, W { slot: slot }]
    let x = a[0]
    let y = a[1]

fn main:
    var count = 0
    run(&raw mut count)
    if count == 2:
        print("ok")
    else:
        print_i32(count)
