// #1430 fixture module (behav_1430_cross_module_declared_later.w): inside a
// module, an enum above the types it carries; and the types a root-module
// enum carries, which reach codegen after the root's own declarations.

pub enum ModOuter:
    Has(i: ModLater, k: i64)
    Tagged(e: ModE)
    None1

pub type ModInner { x: i64, y: i64 }

pub enum ModE:
    A(n: i32)
    B(a: i32, b: i64)

pub type ModLater { p: i64, q: i64 }
