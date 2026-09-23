//! expect-error: expected an indented block after ':'

// #1391 (§29.13 Form 2): a top-level function body sits deeper than column 0.
fn seven() -> i32:
return 7

fn main:
    print(f"{seven()}")
