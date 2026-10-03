//! expect-stdout: ok

// #605 + #606: the `?` operator extracts the Ok payload out of a Result, moving
// it into the binding. The Result subject must be consumed so its payload-drop
// does not also free the extracted value (which would count 2).

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn get(slot: *mut i32) -> Result[W, i32]:
    Ok(W { slot: slot })

fn run(slot: *mut i32) -> Result[i32, i32]:
    let w = get(slot)?
    Ok(0)

fn main:
    var count = 0
    let _ = run(&raw mut count)
    if count == 1:
        print("ok")
    else:
        print_i32(count)
