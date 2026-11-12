//! expect-check-fail: expected 'callbacks none'

use c_import("int calculate(int value);")
c contract arithmetic:
    fn calculate
        callbacks quiet
fn main: ()
