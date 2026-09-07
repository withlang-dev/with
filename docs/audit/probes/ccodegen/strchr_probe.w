extern fn strchr(s: *const i8, c: i32) -> *mut i8

fn main -> i32:
  unsafe:
    let p = strchr("hello" as *const i8, 101)
    if p == 0 as *mut i8: print("null") else: print("found")
  0
