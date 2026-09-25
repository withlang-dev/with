//! expect-stdout: ok
use ForeignPairState

fn step(action: i32, place: i32, source: i32, op: i32, guard: i32, can_fail: bool) -> ForeignPairStep:
    ForeignPairStep { action, place, source, contract: ForeignPairBlock { action: op, ty: 17, origin: 3, guard, can_fail, preserves_on_failure: true, invokes: op == FOREIGN_PAIR_DESTROY } }

fn main:
    let starts: Vec[i32] = Vec.new()
    let counts: Vec[i32] = Vec.new()
    let steps: Vec[ForeignPairStep] = Vec.new()
    // bb0: construct a and borrow it as r, then set its callback.
    starts.push(0)
    counts.push(3)
    steps.push(step(FOREIGN_STEP_APPLY, 0, -1, FOREIGN_PAIR_CREATE, -1, false))
    steps.push(step(FOREIGN_STEP_BORROW, 1, 0, FOREIGN_PAIR_KEEP, -1, false))
    steps.push(step(FOREIGN_STEP_APPLY, 1, -1, FOREIGN_PAIR_CALLBACK, 10, true))
    // bb1: first setter succeeded; the second can fail.
    starts.push(3)
    counts.push(1)
    steps.push(step(FOREIGN_STEP_APPLY, 1, -1, FOREIGN_PAIR_USERDATA, 11, true))
    // bb2: actual cleanup. Its predecessors include later-numbered blocks.
    starts.push(4)
    counts.push(2)
    steps.push(step(FOREIGN_STEP_APPLY, 0, -1, FOREIGN_PAIR_DESTROY, -1, false))
    steps.push(step(FOREIGN_STEP_EXPIRE, 3, -1, FOREIGN_PAIR_KEEP, -1, false))
    // bb3: on success, userdata cannot die before the resource.
    starts.push(6)
    counts.push(1)
    steps.push(step(FOREIGN_STEP_EXPIRE, 3, -1, FOREIGN_PAIR_KEEP, -1, false))
    // bb4: second setter failed; reset permits callback-capable cleanup.
    starts.push(7)
    counts.push(1)
    steps.push(step(FOREIGN_STEP_APPLY, 1, -1, FOREIGN_PAIR_RESET, -1, false))
    let edges: Vec[ForeignPairEdge] = Vec.new()
    edges.push(ForeignPairEdge { from: 0, to: 1, guard: 10, succeeded: true })
    edges.push(ForeignPairEdge { from: 0, to: 2, guard: 10, succeeded: false })
    edges.push(ForeignPairEdge { from: 1, to: 3, guard: 11, succeeded: true })
    edges.push(ForeignPairEdge { from: 1, to: 4, guard: 11, succeeded: false })
    edges.push(ForeignPairEdge { from: 3, to: 2, guard: -1, succeeded: true })
    edges.push(ForeignPairEdge { from: 4, to: 2, guard: -1, succeeded: true })
    let entry = foreign_pair_places(4)
    let checked = foreign_pair_place_flow(starts, counts, steps, edges, entry)
    assert(checked.violations.len() == 1 and checked.violations[0] == 6)
    // Keeping the userdata alive makes every path safe, including a failed
    // second setter followed by reset and callback-capable destruction.
    steps[6] = step(FOREIGN_STEP_APPLY, 0, -1, FOREIGN_PAIR_KEEP, -1, false)
    assert(foreign_pair_place_flow(starts, counts, steps, edges, entry).violations.len() == 0)
    // Removing that reset must expose the incompatibility at actual cleanup.
    steps[7] = step(FOREIGN_STEP_APPLY, 1, -1, FOREIGN_PAIR_KEEP, -1, false)
    let rejected = foreign_pair_place_flow(starts, counts, steps, edges, entry)
    assert(rejected.violations.len() == 1 and rejected.violations[0] == 4)
    print("ok")
