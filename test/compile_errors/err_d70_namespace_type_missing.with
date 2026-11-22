//! expect-error: provides no type 'Nope'

// D70 (§18.2, #1757): a namespaced type annotation names the import's type
// by identity; one the import does not declare is refused, never silently
// inferred from the initializer.

use d70.shapes

fn main:
    let c: shapes.Nope = shapes.Pt.new(7)
    print(c.x)
