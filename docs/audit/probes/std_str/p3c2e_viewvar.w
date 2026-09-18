use std.string

fn main:
    let s = "abc"
    print(f"vlen_var={view_len(s)}")
    print(f"ve_t={view_is_empty(s)}")
    print(f"veq={view_eq(s, s)}")
