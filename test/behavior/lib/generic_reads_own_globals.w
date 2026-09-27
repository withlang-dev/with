// #1743 helper: a generic fn and a generic method read this module's
// private and public values; the importer declares none of them.
pub let K: i32 = 5
let HIDDEN: i32 = 30
const LIMIT: i32 = 700
global var hits = 4000

pub fn g[T](a: T) -> i32: K + HIDDEN + LIMIT

pub fn bump[T](a: T) -> i32:
    hits = hits + 1
    hits

pub type Cell[T] { v: T }
extend Cell[T]:
    pub fn scaled(self: &Self) -> i32: HIDDEN * 2
