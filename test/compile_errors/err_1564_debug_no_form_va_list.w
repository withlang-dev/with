//! expect-check-fail: cannot format a value of type 'c_va_list' with :? — §15.4.7 gives it no Debug form

// D71 / §15.4.7 (#1564): a `va_list` has no Debug form.

pub fn count(args: c_va_list) -> i32:
    print(f"{args:?}")
    0

fn main:
    print("unreached")
