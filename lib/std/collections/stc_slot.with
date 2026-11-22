// std.collections.stc_slot — facade-owned storage for values the migrated
// STC engines index (stdlib_sourcing_plan.md, Phase 3, the
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

// The slot's lifetime, in three safe steps the facades share: `stc_slot_new`
// moves a value into a fresh slot (the engine is then handed the slot's
// address, the one `unsafe` left in a facade is that engine call);
// `stc_slot_view` observes the value in a slot the engine still indexes
// (D22: the view is of the value where it sits); `stc_slot_take` transfers
// the value back out of a slot the engine no longer indexes and frees the
// slot (D27: never a second live value).

/// A fresh slot holding `value`, its prefix dispatching to `compare` and
/// `hash`; the engine indexes it by this address.
pub fn stc_slot_new[T](value: T, compare: fn(*const u8, *const u8) -> i32, hash: fn(*const u8) -> u64) -> *mut stc_slot_head:
    let slot = with_alloc(sizeof[StcSlot[T]]() as i64) as *mut StcSlot[T]
    unsafe { *slot = StcSlot { prefix: stc_slot_prefix(compare, hash), value: value } }
    slot as *mut stc_slot_head

/// The value in a slot the engine indexes (the engine's `stc_slot_head*`
/// cast to the facade's slot type: the cast carries `T`, which a call site
/// never spells).
pub unsafe fn stc_slot_view[T](slot: *const StcSlot[T]) -> &T:
    unsafe { &(*slot).value }

/// Transfers the value out of a slot the engine has released and frees
/// the slot.
pub unsafe fn stc_slot_take[T](slot: *mut StcSlot[T]) -> T:
    var owned = slot
    let value: T = unsafe { move owned.value }
    with_free(slot as *mut u8)
    value

/// Drops the value in a slot the engine has released and frees the slot.
pub unsafe fn stc_slot_release[T](slot: *mut StcSlot[T]):
    let value: T = stc_slot_take(slot)
    drop(value)

/// A probe for a lookup: the engine compares and hashes it through its
/// own callbacks like a stored slot, so it carries the prefix and a byte
/// image of `value` that is never read back as owned. Freed with
/// `stc_slot_discard_probe`, never taken.
pub fn stc_slot_probe[T](value: &T, compare: fn(*const u8, *const u8) -> i32, hash: fn(*const u8) -> u64) -> *mut stc_slot_head:
    let probe = with_alloc(sizeof[StcSlot[T]]() as i64) as *mut StcSlot[T]
    unsafe { (*probe).prefix = stc_slot_prefix(compare, hash) }
    with_memcpy(unsafe { &raw mut (*probe).value } as *mut u8, &raw const *value as *const u8, sizeof[T]() as i64)
    probe as *mut stc_slot_head

pub fn stc_slot_discard_probe(probe: *mut stc_slot_head): with_free(probe as *mut u8)

/// A map's entry: the slot prefix, the key, the value. A `StcSlot[K]` probe
/// has the same prefix and the key at the same offset, so the engine
/// compares it like a stored entry without a value. The same three steps
/// as a slot's: `stc_entry_new`, the key and value views, `stc_entry_take`.
pub type StcEntry[K, V] { prefix: StcSlotPrefix, key: K, value: V }

pub fn stc_entry_new[K, V](key: K, value: V, compare: fn(*const u8, *const u8) -> i32, hash: fn(*const u8) -> u64) -> *mut stc_slot_head:
    let entry = with_alloc(sizeof[StcEntry[K, V]]() as i64) as *mut StcEntry[K, V]
    unsafe { *entry = StcEntry { prefix: stc_slot_prefix(compare, hash), key: key, value: value } }
    entry as *mut stc_slot_head

pub unsafe fn stc_entry_key[K, V](entry: *const StcEntry[K, V]) -> &K:
    unsafe { &(*entry).key }

pub unsafe fn stc_entry_value[K, V](entry: *const StcEntry[K, V]) -> &V:
    unsafe { &(*entry).value }

/// Transfers the value out of an entry the engine has released; the key
/// drops and the entry is freed.
pub unsafe fn stc_entry_take[K, V](entry: *mut StcEntry[K, V]) -> V:
    var owned = entry
    let key: K = unsafe { move owned.key }
    drop(key)
    let value: V = unsafe { move owned.value }
    with_free(entry as *mut u8)
    value

/// Drops both halves of an entry the engine has released and frees it.
pub unsafe fn stc_entry_release[K, V](entry: *mut StcEntry[K, V]):
    let value: V = stc_entry_take(entry)
    drop(value)
