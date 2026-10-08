//! expect-check-fail: or demand an owned `str` (`: str` on the binding or the return) to copy it

// D111 with D22 §6.2: a str is Copy, so a view into a temporary is copied by
// an owned demand, the annotation. The diagnostic names it, never `.clone()`.
fn main:
    let line = "x\ty"
    let f = line.split("\t")[0]
    print(f)
