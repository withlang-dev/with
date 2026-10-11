// #1703 fixture module: its private `SCALE` and its `hits` share names with
// displaced_global_owner's; it imports the owner and reads its pub LIMIT.
use displaced_global_owner
let SCALE: i32 = 7
global var hits: i32 = 100
pub fn other_limit() -> i32: LIMIT * SCALE
pub fn other_hit() -> i32:
    hits = hits + 1
    hits
