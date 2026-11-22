//! expect-stdout: ok

use issue61_queries.builtins
use issue61_queries.cache_keys
use issue61_queries.long_names
use issue61_queries.ordering
use issue61_queries.receivers
use issue61_queries.samples

fn local_forward_score() -> i32:
    var total = builtin_score(sample_state(), sample_lookup())
    total = total + alias_and_temporary_score(sample_state())
    total = total + cache_key_score()
    total = total + long_name_score()
    total

fn main:
    assert(local_forward_score() == 127)
    assert(local_forward_score() == forward_score())
    print("ok")
