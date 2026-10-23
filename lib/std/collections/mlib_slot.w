// std.collections.mlib_slot — facade-owned storage for keys the migrated
// M*LIB B+tree orders (docs/proposals/stdlib_sourcing_plan.md, Phase 4; the
// engine_slot pattern of D148). The tree is instantiated once, over slot
// pointers, in the corpus's facade shapes unit (std.engines.mlib.facade_shapes).
// A B+tree copies keys into its internal nodes as separators, so the engine
// owns every slot it holds: `INIT_SET` clones a slot through the With
// callback in its head (the key cloned), `CLEAR` drops it, and every slot
// points back at the facade's entry (the key and, for a map, the value). The
// facade owns the entries (D37: the engine sees pointers and bytes).

use std.traits
use std.engines.mlib.defs
use rt.rt_core

/// The head every slot shares: the engine's own `mlib_slot_head` (the C-ABI
/// callbacks it calls and the entry it belongs to), then the With comparator,
/// cloner and dropper those callbacks dispatch to. A probe the facade builds
/// for a lookup has this same prefix, so the engine compares it like a
/// stored slot.
pub type MlibSlotPrefix { head: mlib_slot_head, compare: fn(*const u8, *const u8) -> i32, clone_fn: fn(*const u8) -> *mut u8, drop_fn: fn(*mut u8) -> Unit }

/// One engine pointer target: the prefix, then the key.
pub type MlibSlot[T] { prefix: MlibSlotPrefix, key: T }

/// The C-ABI comparison the facade shapes unit's `CMP` calls. (#1135: a
/// closure written in a generic function cannot itself be handed to the
/// engine; these trampolines are the C-ABI functions.)
pub unsafe fn mlib_slot_compare(a: *const c_void, b: *const c_void) -> c_int:
    let compare = (*(a as *const MlibSlotPrefix)).compare.clone()
    compare(a as *const u8, b as *const u8) as c_int

/// The C-ABI clone `INIT_SET` calls: a new slot with the key cloned, the
/// same prefix and entry.
pub unsafe fn mlib_slot_clone_slot(p: *const c_void) -> *mut c_void:
    let clone = (*(p as *const MlibSlotPrefix)).clone_fn.clone()
    clone(p as *const u8) as *mut c_void

/// The C-ABI drop `CLEAR` calls: the key dropped, the slot freed.
pub unsafe fn mlib_slot_drop_slot(p: *mut c_void):
    let release = (*(p as *const MlibSlotPrefix)).drop_fn.clone()
    release(p as *mut u8)

/// The prefix every slot of a facade carries: the engine's callbacks are the
/// trampolines, the With functions are the facade's, the entry is the
/// facade's record (null in a probe).
pub fn mlib_slot_prefix(compare: fn(*const u8, *const u8) -> i32, clone_fn: fn(*const u8) -> *mut u8, drop_fn: fn(*mut u8) -> Unit, entry: *mut u8) -> MlibSlotPrefix:
    MlibSlotPrefix { head: mlib_slot_head { cmp: mlib_slot_compare, clone: mlib_slot_clone_slot, drop: mlib_slot_drop_slot, entry: entry as *mut c_void }, compare: compare, clone_fn: clone_fn, drop_fn: drop_fn }
