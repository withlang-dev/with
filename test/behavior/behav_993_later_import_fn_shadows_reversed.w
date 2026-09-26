//! expect-stdout: 1 3

// #993 (§18.2, Eric's ruling on #1221): helper_c imports helper_a and both
// provide `helper`. Here helper_a's import is written last, so `helper()` is
// helper_a's `1`; the flat merge ordered modules by dependency (helper_a
// before helper_c) and let helper_c's win whatever the program wrote.
// pick_c writes a named import of helper_c's last and gets its `3`.

use issue993.helper_c
use issue993.pick_c
use issue993.helper_a

fn main:
    print(f"{helper()} {via_c()}")
