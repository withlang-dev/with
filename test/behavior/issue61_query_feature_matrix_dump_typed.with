//! args: --dump-typed
//! expect-check-stdout: bind combined: i32

use issue61_queries.ordering

fn main:
    let combined = forward_score() + reverse_score() + repeated_score()
    let shaped = feature_matrix_score()
    let sink = combined + shaped
    assert(sink == 1270)
