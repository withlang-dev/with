use issue61_queries.builtins
use issue61_queries.cache_keys
use issue61_queries.long_names
use issue61_queries.receivers
use issue61_queries.samples

pub fn forward_score() -> i32:
    var total = builtin_score(sample_state(), sample_lookup())
    total = total + alias_and_temporary_score(sample_state())
    total = total + cache_key_score()
    total = total + long_name_score()
    total

pub fn reverse_score() -> i32:
    var total = long_name_score()
    total = total + cache_key_score()
    total = total + alias_and_temporary_score(sample_state())
    total = total + builtin_score(sample_state(), sample_lookup())
    total

pub fn repeated_score() -> i32:
    let first = forward_score()
    let second = reverse_score()
    first + second + forward_score()

pub fn feature_matrix_score() -> i32:
    let forward = forward_score()
    let reverse = reverse_score()
    forward + reverse + repeated_score()
