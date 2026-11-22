//! expect-check-fail: expected 'callbacks none'
//! expect-check-fail: = help: move the statement inside `fn main`, or remove `fn main` to use implicit main mode

use c_import("int calculate(int value);")
c contract arithmetic:
    fn calculate
        callbacks quiet
fn main: ()
