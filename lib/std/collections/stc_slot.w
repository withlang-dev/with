// std.collections.stc_slot — facade-owned storage for values the migrated
// STC engines index (docs/proposals/stdlib_sourcing_plan.md, Phase 3, the
// generic-over-templates design item). STC's templates are instantiated
// once per shape in the corpus's facade shapes unit
// (std.engines.stc.facade_shapes); an arbitrary With value rides the slot
// shape: the engine holds pointers to slots the facade owns, and every
// comparison or hash the engine needs goes through the C-ABI callbacks in
// the slot's head to the With comparator and hasher stored right after it.
// The facade owns every value (D37: the engine sees pointers and bytes).

use std.hash
use std.traits
use std.engines.stc.defs

/// The head every STC slot shares, whatever its value: the engine's own
/// `stc_slot_head` (the C-ABI callbacks it calls), then the With comparator
/// and hasher those callbacks dispatch to. A probe the facade builds for a
/// lookup has this same prefix, so the engine compares it like a stored slot.
pub type StcSlotPrefix { head: stc_slot_head, compare: fn(*const u8, *const u8) -> i32, hash: fn(*const u8) -> u64 }

/// One engine pointer target: the prefix, then the value. A slot is written
/// once by the facade that allocates it and read back exactly once when the
/// value transfers out (remove, pop, drop).
pub type StcSlot[T] { prefix: StcSlotPrefix, value: T }

/// The C-ABI comparison the facade shapes unit's `i_cmp`/`i_less`/`i_eq`
/// call: both operands are slots (or a probe) with the With comparator in
/// the prefix. (#1135: a closure written in a generic function cannot itself
/// be handed to the engine; this trampoline is the one C-ABI function.)
pub unsafe fn stc_slot_compare(a: *const c_void, b: *const c_void) -> c_int:
    let compare = (*(a as *const StcSlotPrefix)).compare.clone()
    compare(a as *const u8, b as *const u8) as c_int

/// The C-ABI hash the shapes unit's `i_hash` calls.
pub unsafe fn stc_slot_hash(p: *const c_void) -> c_ulong:
    let hash = (*(p as *const StcSlotPrefix)).hash.clone()
    hash(p as *const u8) as c_ulong

/// The hasher of a slot whose engine never hashes (ordered engines, the
/// priority queue, the deque).
pub fn stc_slot_unhashed(p: *const u8) -> u64: 0

/// The comparator of a slot whose engine never compares (the deque).
pub fn stc_slot_unordered(a: *const u8, b: *const u8) -> i32: 0

/// The prefix every slot of a facade carries: the engine's callbacks are
/// the two trampolines, the With functions are the facade's.
pub fn stc_slot_prefix(compare: fn(*const u8, *const u8) -> i32, hash: fn(*const u8) -> u64) -> StcSlotPrefix:
    StcSlotPrefix { head: stc_slot_head { cmp: Some(stc_slot_compare), hash: Some(stc_slot_hash) }, compare: compare, hash: hash }
