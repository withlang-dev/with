//! expect-stdout: 5 7 local

// D70 (§18.2, #1757): a namespaced type stays reachable where another
// declaration shadows its short name. This module declares its own `Pt`;
// `shapes.Pt` — as a static-call receiver and as a type annotation — is
// shapes' `Pt` by identity, and the bare `Pt` is this module's.

use d70.shapes

type Pt { y: str }

fn main:
    let q = shapes.Pt.new(5)
    let c: shapes.Pt = shapes.Pt.new(7)
    let mine = Pt { y: "local" }
    print(f"{q.x} {c.x} {mine.y}")
