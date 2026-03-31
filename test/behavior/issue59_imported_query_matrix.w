//! expect-stdout: ok

use issue59_queries.builtins
use issue59_queries.generic
use issue59_queries.methods
use issue59_queries.samples

fn main:
    assert(builtin_score(sample_state(), sample_lookup()) == 25)
    assert(method_score(sample_state(), sample_lookup()) == 16)
    assert(cell_sum(sample_cells()) == 10)
    print("ok")
