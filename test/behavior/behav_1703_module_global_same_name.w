//! expect-stdout: 30 70 5
//! expect-stdout: 1 101 2 102 1000
//! expect-stdout: owner root
//! expect-stdout: 6.28319 42

// #1703 (§18.2, §18.3): a module's top-level values are its own. Two
// modules may each declare `SCALE` (private) and `hits`; the root declares
// `LIMIT`, `hits` and `TAG` as well, and a `PI` beside `use std.math`. Each
// module's references bind its own declaration — a current-module
// declaration is tier 2 and beats every import — and `other` reads the
// owner's pub `LIMIT` through its import. Every collision here was
// "shadowing is not allowed" at the second declaration, whichever module
// it was in.
use displaced_global_owner
use displaced_global_other
use std.math

let LIMIT = 5
global var hits = 1000
const TAG: str = "root"
let PI = 42

fn main:
    print(f"{owner_limit()} {other_limit()} {LIMIT}")
    print(f"{owner_hit()} {other_hit()} {owner_hit()} {other_hit()} {hits}")
    print(f"{owner_tag()} {TAG}")
    print(f"{TAU} {PI}")
