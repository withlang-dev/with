//! expect-error: 'shapes.Pt' names module

// D70 (§18.2): types keep their short names, so `shapes.Pt` can reach the
// module's type only where `Pt` resolves to it. Here this module declares
// its own `Pt`; the namespaced static call is refused loudly instead of
// silently calling this module's type.

use d70.shapes

type Pt { y: str }

fn main:
    let q = shapes.Pt.new(5)
    print(q.x)
