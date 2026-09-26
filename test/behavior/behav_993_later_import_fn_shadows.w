//! expect-stdout: 2 2

// #993 (§18.2, Eric's ruling on #1221): two explicit imports of the same fn
// name resolve to the import written last — named imports and whole-module
// imports alike. behav_993_later_import_fn_shadows_reversed.w writes them the
// other way round and gets 1.

use issue993.helper_a.helper
use issue993.helper_b.helper

fn main:
    print(f"{helper()} {helper()}")
