// The finite domain for a modeled callback/userdata slot. Sema supplies the
// slot, types, success condition and operation effects; MIR supplies the CFG.
// A row describes possible foreign states, never how many setters were seen.
// Zero is the foreign default on both sides. -1/-1 is a compatible pair
// supplied by a caller whose concrete userdata type is not known here.
type ForeignPairAlternative {
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

// D194 (§16.2b.5, §16.2b.9): a retained pointer borrow the resource holds —
// the variadic slot that set it and the key of the storage it borrows. A
// resource holds several at once; each ends at its own release.
type ForeignRetention {
    slot: i32,
    origin: i32,
    // The status key of a release that has not yet been decided (-1: none):
    // a release by an operation that can fail takes effect on its success
    // edge only (foreign_pair_on_edge); on the failure edge the storage is
    // still held.
    pending_guard: i32,
}
impl Copy for ForeignRetention

type ForeignPairState {
    alternatives: List[ForeignPairAlternative],
    held: List[ForeignRetention],
}

fn foreign_pair_alternative_equal(a: &ForeignPairAlternative, b: &ForeignPairAlternative) -> bool:
    a.callback_type == b.callback_type and a.userdata_type == b.userdata_type and a.userdata_origin == b.userdata_origin and a.guard == b.guard and a.succeeded == b.succeeded

fn foreign_pair_add(mut state: ForeignPairState, alternative: ForeignPairAlternative):
    for existing in state.alternatives:
        if foreign_pair_alternative_equal(existing, alternative): return
    state.alternatives.push(alternative)

fn foreign_pair_hold(mut state: ForeignPairState, retention: ForeignRetention):
    for existing in state.held:
        if existing.slot == retention.slot and existing.origin == retention.origin and existing.pending_guard == retention.pending_guard: return
    state.held.push(retention)

fn foreign_pair_held_copy(held: &List[ForeignRetention]) -> List[ForeignRetention]:
    [r for r in held]

fn foreign_pair_empty() -> ForeignPairState: ForeignPairState { alternatives: [], held: [] }

fn foreign_pair_initial(defaults: bool) -> ForeignPairState:
    var state = foreign_pair_empty()
    let ty = if defaults: 0 else: -1
    foreign_pair_add(state, ForeignPairAlternative { callback_type: ty, userdata_type: ty, userdata_origin: -1, guard: -1, succeeded: true })
    state

fn foreign_pair_join(a: &ForeignPairState, b: &ForeignPairState) -> ForeignPairState:
    var result = foreign_pair_empty()
    for alternative in a.alternatives: foreign_pair_add(result, alternative)
    for alternative in b.alternatives: foreign_pair_add(result, alternative)
    for retention in a.held: foreign_pair_hold(result, retention)
    for retention in b.held: foreign_pair_hold(result, retention)
    result

fn foreign_pair_held_equal(a: &List[ForeignRetention], b: &List[ForeignRetention]) -> bool:
    if a.len() != b.len(): return false
    for ra in a:
        var found = false
        for rb in b:
            if ra.slot == rb.slot and ra.origin == rb.origin and ra.pending_guard == rb.pending_guard: found = true
        if not found: return false
    true

fn foreign_pair_equal(a: &ForeignPairState, b: &ForeignPairState) -> bool:
    if a.alternatives.len() != b.alternatives.len(): return false
    for aa in a.alternatives:
        var found = false
        for ab in b.alternatives:
            if foreign_pair_alternative_equal(aa, ab): found = true
        if not found: return false
    foreign_pair_held_equal(a.held, b.held)

// A failed setter preserves the previous pair only when Sema's foreign
// contract explicitly supplies that guarantee. Otherwise both components
// become unknown/incompatible and a modeled reset is required.
fn foreign_pair_set(state: &ForeignPairState, callback: bool, ty: i32, origin: i32, guard: i32, can_fail: bool, preserves_on_failure: bool) -> ForeignPairState:
    var result = ForeignPairState { alternatives: [], held: foreign_pair_held_copy(state.held) }
    for previous in state.alternatives:
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

// Along a branch on a setter's status: the alternatives that outcome
// leaves, and each release pending on that status decided — released on
// the success edge, still held on the failure edge (D194).
fn foreign_pair_on_edge(state: &ForeignPairState, guard: i32, succeeded: bool) -> ForeignPairState:
    var result = ForeignPairState { alternatives: [], held: [] }
    for alternative in state.alternatives:
        if guard < 0 or alternative.guard != guard or alternative.succeeded == succeeded:
            foreign_pair_add(result, alternative)
    for r in state.held:
        if guard < 0 or r.pending_guard != guard: foreign_pair_hold(result, r)
        else if not succeeded: foreign_pair_hold(result, ForeignRetention { slot: r.slot, origin: r.origin, pending_guard: -1 })
    result

fn foreign_pair_can_invoke(state: &ForeignPairState) -> bool:
    for alternative in state.alternatives:
        if alternative.callback_type < -1 or alternative.callback_type != alternative.userdata_type:
            return false
    true

// Whether the resource may hold `origin`: as its callback userdata, or as a
// retained pointer case's storage (D194).
fn foreign_pair_retains_origin(state: &ForeignPairState, origin: i32) -> bool:
    if origin < 0: return false
    for alternative in state.alternatives:
        if alternative.userdata_origin == origin: return true
    for retention in state.held:
        if retention.origin == origin: return true
    false

pub const FOREIGN_PAIR_KEEP: i32 = 0
pub const FOREIGN_PAIR_CALLBACK: i32 = 1
pub const FOREIGN_PAIR_USERDATA: i32 = 2
pub const FOREIGN_PAIR_RESET: i32 = 3
pub const FOREIGN_PAIR_INVOKE: i32 = 4
pub const FOREIGN_PAIR_DESTROY: i32 = 5
pub const FOREIGN_PAIR_CREATE: i32 = 6
// An operation Sema did not model on the resource (a helper call receiving
// it): the pair may have changed in any way, so it is incompatible until a
// modeled reset — the retained origins are still held.
pub const FOREIGN_PAIR_UNKNOWN: i32 = 7
// D194: a retained pointer setter — the resource holds the storage its
// argument borrows, under the setter's slot, until a release.
pub const FOREIGN_PAIR_RETAIN: i32 = 8

fn foreign_pair_unknown(state: &ForeignPairState) -> ForeignPairState:
    var result = ForeignPairState { alternatives: [], held: foreign_pair_held_copy(state.held) }
    for alternative in state.alternatives:
        foreign_pair_add(result, ForeignPairAlternative { callback_type: -2, userdata_type: -3, userdata_origin: alternative.userdata_origin, guard: -1, succeeded: true })
    result

// Whether any alternative still holds a retained userdata origin, or any
// retained pointer case is live: a resource in that state is ephemeral
// (§16.2b.9) and cannot escape.
fn foreign_pair_retains_any(state: &ForeignPairState) -> bool:
    if state.held.len() > 0: return true
    for alternative in state.alternatives:
        if alternative.userdata_origin >= 0: return true
    false

fn foreign_pair_absent() -> ForeignPairState:
    var state = foreign_pair_empty()
    foreign_pair_add(state, ForeignPairAlternative { callback_type: -4, userdata_type: -4, userdata_origin: -1, guard: -1, succeeded: true })
    state

// D194: the bit a retained slot occupies in a release mask (a shift count
// is unsigned, so the index is cast once, here).
fn foreign_slot_bit(slot: i32) -> i64: 1 << (slot as u32)

// D194: the retentions an operation releases (`until`, a bit per slot),
// and a setter's own slot replaced by its new storage.
fn foreign_pair_release(state: &ForeignPairState, mask: i64, guard: i32) -> ForeignPairState:
    let result = foreign_pair_on_edge(state, -1, true)
    result.held = if guard < 0: [r for r in state.held if mask & foreign_slot_bit(r.slot) == 0] else: [if mask & foreign_slot_bit(r.slot) == 0: r else: ForeignRetention { slot: r.slot, origin: r.origin, pending_guard: guard } for r in state.held]
    result

fn foreign_pair_retain(state: &ForeignPairState, slot: i32, origin: i32, guard: i32) -> ForeignPairState:
    var result = foreign_pair_release(state, foreign_slot_bit(slot), guard)
    if origin >= 0: foreign_pair_hold(result, ForeignRetention { slot, origin, pending_guard: -1 })
    result

type ForeignPairBlock {
    action: i32,
    ty: i32,
    origin: i32,
    guard: i32,
    can_fail: bool,
    preserves_on_failure: bool,
    invokes: bool,
    slot: i32,        // D194: the retained slot a FOREIGN_PAIR_RETAIN sets, or -1
    releases: i64,    // D194: the retained slots the operation releases (a bit per slot)
}
impl Copy for ForeignPairBlock

type ForeignPairEdge {
    from: i32,
    to: i32,
    guard: i32,
    succeeded: bool,
}
impl Copy for ForeignPairEdge

type ForeignPairFlow {
    inputs: List[ForeignPairState],
    violations: List[i32],
}

fn foreign_pair_transfer(state: &ForeignPairState, block: &ForeignPairBlock) -> ForeignPairState:
    let released = if block.releases != 0: foreign_pair_release(state, block.releases, block.guard) else: foreign_pair_on_edge(state, -1, true)
    if block.action == FOREIGN_PAIR_CALLBACK or block.action == FOREIGN_PAIR_USERDATA:
        return foreign_pair_set(released, block.action == FOREIGN_PAIR_CALLBACK, block.ty, block.origin, block.guard, block.can_fail, block.preserves_on_failure)
    if block.action == FOREIGN_PAIR_RETAIN:
        return foreign_pair_retain(released, block.slot, block.origin, block.guard)
    if (block.action == FOREIGN_PAIR_RESET or block.action == FOREIGN_PAIR_CREATE) and state.alternatives.len() > 0:
        return foreign_pair_initial(true)
    if block.action == FOREIGN_PAIR_DESTROY and state.alternatives.len() > 0:
        return foreign_pair_absent()
    if block.action == FOREIGN_PAIR_UNKNOWN and state.alternatives.len() > 0:
        return foreign_pair_unknown(released)
    released

// Every predecessor, including backwards edges, contributes until the finite
// set stops growing. Report requirements only after convergence: an early
// sweep's empty row is unreachable, not evidence that cleanup is safe.
fn foreign_pair_flow(blocks: &List[ForeignPairBlock], edges: &List[ForeignPairEdge], entry: &ForeignPairState) -> ForeignPairFlow:
    let inputs = [foreign_pair_empty() for _ in blocks]
    let outputs = [foreign_pair_empty() for _ in blocks]
    var changed = true
    while changed:
        changed = false
        for bi in 0..blocks.len():
            var incoming = if bi == 0: foreign_pair_on_edge(entry, -1, true) else: foreign_pair_empty()
            for edge in edges:
                if edge.to != bi: continue
                assert(edge.from >= 0 and edge.from < blocks.len())
                let along_edge = foreign_pair_on_edge(outputs[edge.from], edge.guard, edge.succeeded)
                incoming = foreign_pair_join(incoming, along_edge)
            let outgoing = foreign_pair_transfer(incoming, blocks[bi])
            if not foreign_pair_equal(outgoing, outputs[bi]): changed = true
            inputs[bi] = incoming
            outputs[bi] = outgoing
    let violations = []
    for bi in 0..blocks.len():
        let block = &blocks[bi]
        if (block.action == FOREIGN_PAIR_INVOKE or block.invokes) and not foreign_pair_can_invoke(inputs[bi]):
            violations.push(bi as i32)
    ForeignPairFlow { inputs, violations }

// A row over canonical owned places. References name possible storage
// places; binding a reference replaces its targets instead of unifying
// resources forever. MIR supplies the canonical keys and move/borrow facts.
// Multiple possible targets require a weak update: either resource may have
// been left unchanged. This deliberately loses correlation, never safety.
type ForeignPairPlaces {
    values: List[ForeignPairState],
    references: List[List[i32]],
}

fn foreign_pair_places(width: i32) -> ForeignPairPlaces:
    ForeignPairPlaces { values: [foreign_pair_absent() for _ in 0..width], references: [[key] for key in 0..width] }

fn foreign_pair_places_clone(source: &ForeignPairPlaces) -> ForeignPairPlaces:
    ForeignPairPlaces { values: [foreign_pair_on_edge(v, -1, true) for v in source.values], references: [[t for t in targets] for targets in source.references] }

fn foreign_pair_places_join(a: &ForeignPairPlaces, b: &ForeignPairPlaces) -> ForeignPairPlaces:
    assert(a.values.len() == b.values.len())
    let result = foreign_pair_places_clone(a)
    for key in 0..a.values.len():
        result.values[key] = foreign_pair_join(a.values[key], b.values[key])
        for target in b.references[key]:
            if not result.references[key].contains(target): result.references[key].push(target)
    result

impl ForeignPairPlaces:
    mut fn borrow(dest: i32, source: i32):
        // Snapshot before replacing: assigning a reference to itself is valid.
        // Seed-bound: the pinned seed mis-lowers a comprehension over an
        // element of a `List[List[T]]` (MirLower.w lower_comprehension_list,
        // fixed in the same change); the `&` names the element as a
        // reference value, which it lowers. `[t for t in self.references[source]]`
        // once a seed carrying the fix is pinned.
        let targets = &self.references[source]
        self.references[dest] = [t for t in targets]

    mut fn move_place(dest: i32, source: i32):
        if dest == source: return
        self.values[dest] = foreign_pair_on_edge(self.values[source], -1, true)
        self.values[source] = foreign_pair_absent()
        // An existing reference to the source still names that storage. Moving
        // the owner cannot silently retarget it and hide an invalidated borrow.

    mut fn apply_at(place: i32, block: &ForeignPairBlock) -> bool:
        let count = self.references[place].len()
        if count == 0: return false
        var valid = true
        for key in self.references[place]:
            if (block.action == FOREIGN_PAIR_INVOKE or block.invokes) and not foreign_pair_can_invoke(self.values[key]): valid = false
            let after = foreign_pair_transfer(self.values[key], block)
            self.values[key] = if count == 1: after else: foreign_pair_join(self.values[key], after)
        valid

fn foreign_pair_origin_live(places: &ForeignPairPlaces, origin: i32) -> bool:
    for value in places.values:
        if foreign_pair_retains_origin(value, origin): return true
    false

fn foreign_pair_places_equal(a: &ForeignPairPlaces, b: &ForeignPairPlaces) -> bool:
    if a.values.len() != b.values.len(): return false
    for key in 0..a.values.len():
        if not foreign_pair_equal(a.values[key], b.values[key]): return false
        if a.references[key].len() != b.references[key].len(): return false
        for target in a.references[key]:
            if not b.references[key].contains(target): return false
    true

// A normalized MIR operation. The adapter supplies owned-place keys and
// Sema's call contract; this domain does not inspect AST names or C options.
pub const FOREIGN_STEP_APPLY: i32 = 0
pub const FOREIGN_STEP_BORROW: i32 = 1
pub const FOREIGN_STEP_MOVE: i32 = 2
pub const FOREIGN_STEP_EXPIRE: i32 = 3
// The resource at `place` leaves the function or its frame (returned, or
// stored into longer-lived storage): valid only while it retains nothing.
pub const FOREIGN_STEP_ESCAPE: i32 = 4

fn foreign_pair_place_retains_any(places: &ForeignPairPlaces, place: i32) -> bool:
    for key in places.references[place]:
        if foreign_pair_retains_any(places.values[key]): return true
    false

type ForeignPairStep {
    action: i32,
    place: i32,
    source: i32,
    contract: ForeignPairBlock,
}
impl Copy for ForeignPairStep

type ForeignPairPlaceFlow {
    inputs: List[ForeignPairPlaces],
    reachable: List[bool],
    // Global step indices, so the MIR adapter can recover exact spans.
    violations: List[i32],
}

fn foreign_pair_execute_step(places: &ForeignPairPlaces, step: &ForeignPairStep) -> (ForeignPairPlaces, bool):
    let after = foreign_pair_places_clone(places)
    var valid = true
    if step.action == FOREIGN_STEP_APPLY:
        valid = after.apply_at(step.place, step.contract)
    else if step.action == FOREIGN_STEP_BORROW:
        after.borrow(step.place, step.source)
    else if step.action == FOREIGN_STEP_MOVE:
        valid = not foreign_pair_origin_live(places, step.source)
        after.move_place(step.place, step.source)
    else if step.action == FOREIGN_STEP_EXPIRE:
        valid = not foreign_pair_origin_live(places, step.place)
    else if step.action == FOREIGN_STEP_ESCAPE:
        valid = not foreign_pair_place_retains_any(places, step.place)
    else:
        panic("invalid foreign pair transfer action")
    (after, valid)

fn foreign_pair_places_edge(source: &ForeignPairPlaces, edge: &ForeignPairEdge) -> (ForeignPairPlaces, bool):
    let result = foreign_pair_places_clone(source)
    var reachable = true
    for key in 0..result.values.len():
        result.values[key] = foreign_pair_on_edge(source.values[key], edge.guard, edge.succeeded)
        if result.values[key].alternatives.len() == 0: reachable = false
    (result, reachable)

fn foreign_pair_place_flow(starts: &List[i32], counts: &List[i32], steps: &List[ForeignPairStep], edges: &List[ForeignPairEdge], entry: &ForeignPairPlaces) -> ForeignPairPlaceFlow:
    assert(starts.len() == counts.len())
    let width = entry.values.len() as i32
    let inputs = [foreign_pair_places(width) for _ in starts]
    let outputs = [foreign_pair_places(width) for _ in starts]
    let reachable = [false for _ in starts]
    var changed = true
    while changed:
        changed = false
        for bi in 0..starts.len():
            var incoming = foreign_pair_places_clone(entry)
            var reached = bi == 0
            for edge in edges:
                if edge.to != bi or not reachable[edge.from]: continue
                let (along, possible) = foreign_pair_places_edge(outputs[edge.from], edge)
                if not possible: continue
                incoming = if reached: foreign_pair_places_join(incoming, along) else: along
                reached = true
            if not reached: continue
            var outgoing = foreign_pair_places_clone(incoming)
            for si in starts[bi]..starts[bi] + counts[bi]:
                let (after, _) = foreign_pair_execute_step(outgoing, steps[si])
                outgoing = after
            if not reachable[bi] or not foreign_pair_places_equal(outgoing, outputs[bi]): changed = true
            reachable[bi] = true
            inputs[bi] = incoming
            outputs[bi] = outgoing
    let violations = []
    for bi in 0..starts.len():
        if not reachable[bi]: continue
        var current = foreign_pair_places_clone(inputs[bi])
        for si in starts[bi]..starts[bi] + counts[bi]:
            let (after, valid) = foreign_pair_execute_step(current, steps[si])
            if not valid: violations.push(si)
            current = after
    ForeignPairPlaceFlow { inputs, reachable, violations }
