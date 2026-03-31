//! expect-stdout: ok

use issue61_queries.orchestrator
use issue61_queries.samples

fn main:
    assert(orchestrated_score() == 43)
    assert(orchestrated_score() == mirrored_score(sample_state(), sample_lookup()))
    print("ok")
