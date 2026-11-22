// #1350 fixture module: imports displaced_fn_owner and calls its pub
// is_digit unqualified; the root's own is_digit is not visible here.
use displaced_fn_owner
fn label() -> str: "importer"
pub fn importer_is_digit(c: i32) -> bool: is_digit(c)
pub fn importer_label() -> str: label()
