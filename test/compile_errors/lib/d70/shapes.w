// D70 fixture: a module whose namespace `shapes` reaches its type, its
// static constructor and a free fn.
pub type Pt { x: i32 }
pub fn Pt.new(x: i32) -> Pt: Pt { x }
pub fn mk(x: i32) -> Pt: Pt { x }
