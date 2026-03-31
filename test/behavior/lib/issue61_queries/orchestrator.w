use issue61_queries.builtins
use issue61_queries.generic
use issue61_queries.normalize
use issue61_queries.samples
use issue61_queries.shared

pub fn mirrored_score(state: State, lookup: HashMap[str, i32]) -> i32:
    var total = builtin_score(state, lookup)
    var i = 0
    while i < state.entries.len():
        total = total + edge_score(state.entries[i].name)
        i = i + 1
    total + cell_sum(sample_cells())

pub fn orchestrated_score() -> i32:
    mirrored_score(sample_state(), sample_lookup())
