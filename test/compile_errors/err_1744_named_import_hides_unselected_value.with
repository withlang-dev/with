//! expect-error: 'Y' is not imported: `use named_import.sel.X` names only what it selects
// #1744 (§18.2): a named import introduces the names it selects. `use
// named_import.sel.X` made every public name of the module visible; `Y` is
// a public name it does not select.

use named_import.sel.X

fn main:
    print(X)
    print(Y)
