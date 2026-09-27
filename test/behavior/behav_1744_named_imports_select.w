//! expect-stdout: 1 5 6 7
// #1744 (§18.2): each name a named import selects is visible, and a whole
// import (or a second named import) brings in the rest.
use named_import.sel.{X, Y}
use named_import.sel.fy
use named_import.sel.Pt

fn main:
    let p = Pt { v: 7 }
    print(f"{X} {Y} {fy()} {p.v}")
