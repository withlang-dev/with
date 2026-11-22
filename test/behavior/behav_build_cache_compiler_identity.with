use BuildGraphCache
use std.process

fn main:
    let identity = build_cache_fingerprint_file(args()[0])
    let first = build_cache_graph_key(".", 0, 0)
    assert(identity.len() == 64)
    assert(first.split(":")[1] == identity)
    for i in 0..3:
        assert(build_cache_graph_key(".", 0, 0) == first)
    let other_target = build_cache_graph_key(".", 1, 0)
    assert(other_target != first)
    assert(other_target.split(":")[1] == identity)
