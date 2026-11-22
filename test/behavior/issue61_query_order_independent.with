//! expect-stdout: ok

use issue61_queries.ordering

fn main:
    let forward = forward_score()
    let reverse = reverse_score()
    let matrix_a = feature_matrix_score()
    let matrix_b = feature_matrix_score()
    assert(forward == reverse)
    assert(forward + reverse + forward == repeated_score())
    assert(matrix_a == 635)
    assert(matrix_b == 635)
    print("ok")
