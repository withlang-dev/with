//! expect-stdout: ok

use issue61_queries.long_names

fn main:
    assert(long_name_score() == 48)
    assert(long_name_score() == 48)
    print("ok")
