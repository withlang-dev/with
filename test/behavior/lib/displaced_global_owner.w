// #1703 fixture module: declares top-level values the root program
// (behav_1703_module_global_same_name.w) and displaced_global_other also
// declare. This module's own references bind its own declarations.
pub let LIMIT: i32 = 10
let SCALE: i32 = 3
global var hits: i32 = 0
pub const TAG: str = "owner"
pub fn owner_limit() -> i32: LIMIT * SCALE
pub fn owner_hit() -> i32:
    hits = hits + 1
    hits
pub fn owner_tag() -> str: TAG
