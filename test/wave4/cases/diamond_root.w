// Diamond import: root -> left + right, both -> shared.
// Tests that shared module is loaded once (deduplication).
use diamond.left
use diamond.right

fn main -> i32:
    left_val() + right_val()
