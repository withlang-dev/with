//! expect-stdout: 735 735
//! expect-stdout: 4001 4002 60
// #1743 (§18.1, §18.3, §9.1c): a generic body's module-level names are its
// module's wherever it is instantiated. The concrete check of a generic
// body started from an empty scope stack, so it saw no module-level value
// at all ("undefined variable" at `K`), while private fns resolved.

use generic_reads_own_globals

fn main:
    print(f"{g(1)} {g(\"s\")}")
    let c = Cell { v: 1.5 }
    print(f"{bump(1)} {bump(true)} {c.scaled()}")
