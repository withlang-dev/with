//! args: --dump-mir
//! expect-check-stdout: mir module functions=

use issue59_queries.generic
use issue59_queries.samples

fn main:
    let _ = cell_sum(sample_cells())
