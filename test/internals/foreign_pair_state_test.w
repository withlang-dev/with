//! expect-stdout: ok

use ForeignPairState

fn block(action: i32, guard: i32, invokes: bool) -> ForeignPairBlock:
    ForeignPairBlock { action, ty: 17, origin: 41, guard, can_fail: true, preserves_on_failure: false, invokes }

fn failure_cleanup_flow:
    var blocks: Vec[ForeignPairBlock] = Vec.new()
    blocks.push(block(FOREIGN_PAIR_CALLBACK, 10, false))
    blocks.push(block(FOREIGN_PAIR_USERDATA, 11, false))
    blocks.push(block(FOREIGN_PAIR_INVOKE, -1, true))
    blocks.push(block(FOREIGN_PAIR_DESTROY, -1, true))
    blocks.push(block(FOREIGN_PAIR_RESET, -1, false))
    blocks.push(block(FOREIGN_PAIR_RESET, -1, false))
    let edges: Vec[ForeignPairEdge] = Vec.new()
    edges.push(ForeignPairEdge { from: 0, to: 1, guard: 10, succeeded: true })
    edges.push(ForeignPairEdge { from: 0, to: 5, guard: 10, succeeded: false })
    edges.push(ForeignPairEdge { from: 1, to: 2, guard: 11, succeeded: true })
    edges.push(ForeignPairEdge { from: 1, to: 4, guard: 11, succeeded: false })
    edges.push(ForeignPairEdge { from: 2, to: 3, guard: -1, succeeded: true })
    edges.push(ForeignPairEdge { from: 4, to: 3, guard: -1, succeeded: true })
    edges.push(ForeignPairEdge { from: 5, to: 3, guard: -1, succeeded: true })
    let defaults = foreign_pair_initial(true)
    assert(foreign_pair_flow(blocks, edges, defaults).violations.len() == 0)
    // Cleanup block 3 precedes the failing arms that feed it. It must see
    // their state, not accept its first empty input as a safety proof.
    blocks[4] = block(FOREIGN_PAIR_KEEP, -1, false)
    let unsafe_cleanup = foreign_pair_flow(blocks, edges, defaults)
    assert(unsafe_cleanup.violations.len() == 1 and unsafe_cleanup.violations[0] == 3)
    blocks[3] = block(FOREIGN_PAIR_DESTROY, -1, false)
    assert(foreign_pair_flow(blocks, edges, defaults).violations.len() == 0)

    // A destroyed value is absent, not an unreachable control-flow path.
    // Reusing its storage next iteration must establish a fresh default.
    let loop_blocks: Vec[ForeignPairBlock] = Vec.new()
    loop_blocks.push(block(FOREIGN_PAIR_CREATE, -1, false))
    loop_blocks.push(block(FOREIGN_PAIR_DESTROY, -1, true))
    loop_blocks.push(block(FOREIGN_PAIR_KEEP, -1, false))
    let loop_edges: Vec[ForeignPairEdge] = Vec.new()
    loop_edges.push(ForeignPairEdge { from: 0, to: 1, guard: -1, succeeded: true })
    loop_edges.push(ForeignPairEdge { from: 1, to: 2, guard: -1, succeeded: true })
    loop_edges.push(ForeignPairEdge { from: 2, to: 0, guard: -1, succeeded: false })
    let looped = foreign_pair_flow(loop_blocks, loop_edges, foreign_pair_absent())
    assert(looped.violations.len() == 0)
    assert(foreign_pair_can_invoke(looped.inputs[1]))
    assert(looped.inputs[2].alternatives.len() > 0 and not foreign_pair_can_invoke(looped.inputs[2]))

fn main:
    failure_cleanup_flow()
    let defaults = foreign_pair_initial(true)
    assert(foreign_pair_can_invoke(defaults))
    assert(foreign_pair_equal(foreign_pair_on_edge(defaults, -1, false), defaults))
    let first = foreign_pair_set(defaults, true, 17, -1, 10, true, true)
    let first_failed = foreign_pair_on_edge(first, 10, false)
    assert(foreign_pair_can_invoke(first_failed))
    let first_succeeded = foreign_pair_on_edge(first, 10, true)
    assert(not foreign_pair_can_invoke(first_succeeded))
    let second = foreign_pair_set(first_succeeded, false, 17, 41, 11, true, true)
    let complete = foreign_pair_on_edge(second, 11, true)
    assert(foreign_pair_can_invoke(complete))
    assert(foreign_pair_retains_origin(complete, 41))

    // Required error path: successful callback setter, failed userdata
    // setter. Callback-capable cleanup must refuse this state. A trusted
    // reset restores the foreign defaults before cleanup and releases the
    // new retention; callback-free destruction needs no invocation check.
    let second_failed = foreign_pair_on_edge(second, 11, false)
    assert(not foreign_pair_can_invoke(second_failed))
    assert(not foreign_pair_retains_origin(second_failed, 41))
    let reset = foreign_pair_initial(true)
    assert(foreign_pair_can_invoke(reset))

    // Replacement is about compatibility, not the number of setters.
    let replaced = foreign_pair_set(complete, true, 29, -1, 12, true, true)
    assert(foreign_pair_can_invoke(foreign_pair_on_edge(replaced, 12, false)))
    assert(not foreign_pair_can_invoke(foreign_pair_on_edge(replaced, 12, true)))
    assert(not foreign_pair_can_invoke(foreign_pair_join(complete, second_failed)))
    assert(foreign_pair_equal(foreign_pair_join(complete, complete), complete))
    // No inference that failure leaves an installation unchanged.
    let unspecified_failure = foreign_pair_set(complete, true, 17, -1, 13, true, false)
    assert(not foreign_pair_can_invoke(foreign_pair_on_edge(unspecified_failure, 13, false)))
    let uncertain_data = foreign_pair_set(complete, false, 29, 42, 14, true, false)
    let uncertain_failure = foreign_pair_on_edge(uncertain_data, 14, false)
    assert(foreign_pair_retains_origin(uncertain_failure, 41))
    assert(foreign_pair_retains_origin(uncertain_failure, 42))
    assert(foreign_pair_can_invoke(foreign_pair_initial(false)))
    print("ok")
