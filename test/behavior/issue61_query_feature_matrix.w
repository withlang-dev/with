//! expect-stdout: ok

use issue61_queries.ordering

fn main:
    assert(forward_score() == 127)
    assert(reverse_score() == 127)
    assert(repeated_score() == 381)
    assert(feature_matrix_score() == 635)
    print("ok")
