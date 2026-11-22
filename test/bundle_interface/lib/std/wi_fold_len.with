// #2219, the count of a literal sequence: `XS.len()` of a module constant
// whose initializer is a literal folds to its element count, so a global
// built from it is initialized data in the bundle (a migrated C
// `sizeof(a) / sizeof(a[0])`: stc's `nr16: Cc_range16.len()`) and a body
// reading it is accepted; `plain` is exported as usual.
pub type Range { lo: i32, hi: i32 }
pub type Group { nr: i32, first: i32 }
let RANGES: List[Range] = [Range { lo: 0, hi: 31 }, Range { lo: 127, hi: 159 }]
pub let GROUP: Group = Group { nr: ((RANGES.len() as u64) as i32), first: RANGES[0].lo }
pub fn group_count() -> i32: GROUP.nr
pub fn plain(x: i32) -> i32: x
