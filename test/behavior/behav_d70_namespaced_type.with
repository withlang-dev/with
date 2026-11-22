//! expect-stdout: 5 6 7

// D70 (§18.2): a module namespace reaches the module's types as well as
// its values and fns — a static constructor through the namespace, a free
// fn, and a namespaced type annotation.

use d70.shapes

fn main:
    let a = shapes.Pt.new(5)
    let b = shapes.mk(6)
    let c: shapes.Pt = shapes.Pt.new(7)
    print(f"{a.x} {b.x} {c.x}")
