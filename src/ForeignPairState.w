// The finite domain for a modeled callback/userdata slot. Sema supplies the
// slot, types, success condition and operation effects; MIR supplies the CFG.
// A row describes possible foreign states, never how many setters were seen.
// Zero is the foreign default on both sides. -1/-1 is a compatible pair
// supplied by a caller whose concrete userdata type is not known here.
pub type ForeignPairAlternative {
    callback_type: i32,
    userdata_type: i32,
    userdata_origin: i32,
    // The most recent setter's MIR result and which outcome led here.
    // A later unrelated branch cannot discard an alternative. Forgetting an
    // older guard loses precision only; it never proves compatibility.
    guard: i32,
    succeeded: bool,
}
impl Copy for ForeignPairAlternative

pub type ForeignPairState {
    alternatives: Vec[ForeignPairAlternative],
}

fn foreign_pair_alternative_equal(a: &ForeignPairAlternative, b: &ForeignPairAlternative) -> bool:
    a.callback_type == b.callback_type and a.userdata_type == b.userdata_type and a.userdata_origin == b.userdata_origin and a.guard == b.guard and a.succeeded == b.succeeded

fn foreign_pair_add(state: &ForeignPairState, alternative: ForeignPairAlternative):
    for i in 0..state.alternatives.len():
        if foreign_pair_alternative_equal(state.alternatives[i], alternative): return
    state.alternatives.push(alternative)

pub fn foreign_pair_initial(defaults: bool) -> ForeignPairState:
    let state = ForeignPairState { alternatives: Vec.new() }
    let ty = if defaults: 0 else: -1
    foreign_pair_add(state, ForeignPairAlternative { callback_type: ty, userdata_type: ty, userdata_origin: -1, guard: -1, succeeded: true })
    state

pub fn foreign_pair_join(a: &ForeignPairState, b: &ForeignPairState) -> ForeignPairState:
    let result = ForeignPairState { alternatives: Vec.new() }
    for i in 0..a.alternatives.len(): foreign_pair_add(result, a.alternatives[i])
    for i in 0..b.alternatives.len(): foreign_pair_add(result, b.alternatives[i])
    result

pub fn foreign_pair_equal(a: &ForeignPairState, b: &ForeignPairState) -> bool:
    if a.alternatives.len() != b.alternatives.len(): return false
    for i in 0..a.alternatives.len():
        var found = false
        for j in 0..b.alternatives.len():
            if foreign_pair_alternative_equal(a.alternatives[i], b.alternatives[j]): found = true
        if not found: return false
    true

// A failed setter preserves the previous pair only when Sema's foreign
// contract explicitly supplies that guarantee. Otherwise both components
// become unknown/incompatible and a modeled reset is required.
pub fn foreign_pair_set(state: &ForeignPairState, callback: bool, ty: i32, origin: i32, guard: i32, can_fail: bool, preserves_on_failure: bool) -> ForeignPairState:
    let result = ForeignPairState { alternatives: Vec.new() }
    for i in 0..state.alternatives.len():
        let previous = &state.alternatives[i]
        foreign_pair_add(result, ForeignPairAlternative {
            callback_type: if callback: ty else: previous.callback_type,
            userdata_type: if callback: previous.userdata_type else: ty,
            userdata_origin: if callback: previous.userdata_origin else: origin,
            guard, succeeded: true,
        })
        if can_fail:
            foreign_pair_add(result, ForeignPairAlternative {
                callback_type: if preserves_on_failure: previous.callback_type else: -2,
                userdata_type: if preserves_on_failure: previous.userdata_type else: -3,
                userdata_origin: previous.userdata_origin,
                guard, succeeded: false,
            })
            if not preserves_on_failure and not callback:
                foreign_pair_add(result, ForeignPairAlternative {
                    callback_type: -2, userdata_type: -3,
                    userdata_origin: origin, guard, succeeded: false,
                })
    result

pub fn foreign_pair_on_edge(state: &ForeignPairState, guard: i32, succeeded: bool) -> ForeignPairState:
    let result = ForeignPairState { alternatives: Vec.new() }
    for i in 0..state.alternatives.len():
        let alternative = &state.alternatives[i]
        if guard < 0 or alternative.guard != guard or alternative.succeeded == succeeded:
            foreign_pair_add(result, alternative)
    result

pub fn foreign_pair_can_invoke(state: &ForeignPairState) -> bool:
    for i in 0..state.alternatives.len():
        let alternative = &state.alternatives[i]
        if alternative.callback_type < -1 or alternative.callback_type != alternative.userdata_type:
            return false
    true

pub fn foreign_pair_retains_origin(state: &ForeignPairState, origin: i32) -> bool:
    if origin < 0: return false
    for i in 0..state.alternatives.len():
        if state.alternatives[i].userdata_origin == origin: return true
    false

pub const FOREIGN_PAIR_KEEP: i32 = 0
pub const FOREIGN_PAIR_CALLBACK: i32 = 1
pub const FOREIGN_PAIR_USERDATA: i32 = 2
pub const FOREIGN_PAIR_RESET: i32 = 3
pub const FOREIGN_PAIR_INVOKE: i32 = 4
pub const FOREIGN_PAIR_DESTROY: i32 = 5
pub const FOREIGN_PAIR_CREATE: i32 = 6

pub fn foreign_pair_absent() -> ForeignPairState:
    let state = ForeignPairState { alternatives: Vec.new() }
    foreign_pair_add(state, ForeignPairAlternative { callback_type: -4, userdata_type: -4, userdata_origin: -1, guard: -1, succeeded: true })
    state

pub type ForeignPairBlock {
    action: i32,
    ty: i32,
    origin: i32,
    guard: i32,
    can_fail: bool,
    preserves_on_failure: bool,
    invokes: bool,
}
impl Copy for ForeignPairBlock

pub type ForeignPairEdge {
    from: i32,
    to: i32,
    guard: i32,
    succeeded: bool,
}
impl Copy for ForeignPairEdge

pub type ForeignPairFlow {
    inputs: Vec[ForeignPairState],
    violations: Vec[i32],
}

fn foreign_pair_transfer(state: &ForeignPairState, block: &ForeignPairBlock) -> ForeignPairState:
    if block.action == FOREIGN_PAIR_CALLBACK or block.action == FOREIGN_PAIR_USERDATA:
        return foreign_pair_set(state, block.action == FOREIGN_PAIR_CALLBACK, block.ty, block.origin, block.guard, block.can_fail, block.preserves_on_failure)
    if (block.action == FOREIGN_PAIR_RESET or block.action == FOREIGN_PAIR_CREATE) and state.alternatives.len() > 0:
        return foreign_pair_initial(true)
    if block.action == FOREIGN_PAIR_DESTROY and state.alternatives.len() > 0:
        return foreign_pair_absent()
    foreign_pair_on_edge(state, -1, true)

// Every predecessor, including backwards edges, contributes until the finite
// set stops growing. Report requirements only after convergence: an early
// sweep's empty row is unreachable, not evidence that cleanup is safe.
pub fn foreign_pair_flow(blocks: &Vec[ForeignPairBlock], edges: &Vec[ForeignPairEdge], entry: &ForeignPairState) -> ForeignPairFlow:
    var inputs: Vec[ForeignPairState] = Vec.new()
    var outputs: Vec[ForeignPairState] = Vec.new()
    for i in 0..blocks.len():
        inputs.push(ForeignPairState { alternatives: Vec.new() })
        outputs.push(ForeignPairState { alternatives: Vec.new() })
    var changed = true
    while changed:
        changed = false
        for bi in 0..blocks.len() as i32:
            var incoming = if bi == 0: foreign_pair_on_edge(entry, -1, true) else: ForeignPairState { alternatives: Vec.new() }
            for ei in 0..edges.len():
                let edge = &edges[ei]
                if edge.to != bi: continue
                assert(edge.from >= 0 and edge.from < blocks.len() as i32)
                let along_edge = foreign_pair_on_edge(outputs[edge.from], edge.guard, edge.succeeded)
                incoming = foreign_pair_join(incoming, along_edge)
            let outgoing = foreign_pair_transfer(incoming, blocks[bi])
            if not foreign_pair_equal(outgoing, outputs[bi]): changed = true
            inputs[bi] = move incoming
            outputs[bi] = outgoing
    let violations: Vec[i32] = Vec.new()
    for bi in 0..blocks.len() as i32:
        let block = &blocks[bi]
        if (block.action == FOREIGN_PAIR_INVOKE or block.invokes) and not foreign_pair_can_invoke(inputs[bi]):
            violations.push(bi)
    ForeignPairFlow { inputs: move inputs, violations }
