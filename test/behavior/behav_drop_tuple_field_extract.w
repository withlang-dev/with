//! expect-stdout: ok

// #605 + #606: extracting tuple elements by field access (`pair.0`, `pair.1`)
// moves them out of the source tuple. The source must be consumed so its
// element-drop does not also free the extracted values. This is the channel
// idiom `let tx = pair.0; let rx = pair.1`. Without the consume, `pair` and the
// extracted bindings both drop -> count 4 (double-free).

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn run(slot: *mut i32):
    let pair = (W { slot: slot }, W { slot: slot })
    let a = pair.0
    let b = pair.1

fn main:
    var count = 0
    run(&raw mut count)
    if count == 2:
        print("ok")
    else:
        print_i32(count)
