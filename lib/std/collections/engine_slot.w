// std.collections.engine_slot — facade-owned storage for values that a
// migrated c-algorithms engine indexes by pointer (docs/stdlib_sourcing_plan.md,
// "What containers add to that pattern"). The engines are raw `void*`
// containers (D37); the facade owns every value, hands the engine one stable
// heap slot per value, and translates between With ownership and the
// engine's calls.

use std.c_algorithms.defs

/// One engine pointer target. The With comparator sits at offset 0 so the
/// engine's comparison callback can find it without knowing `T`; the value
/// follows it. A slot is written once by the facade that allocates it and
/// read back exactly once when the value transfers out (remove, pop, drop).
pub type Slot[T] { compare: fn(*const u8, *const u8) -> i32, value: T }

/// The one C-ABI comparison callback every ordered facade registers with
/// its engine: it reads the With comparator stored in the first slot and
/// compares the two slots through it. (#1135: a closure written in a
/// generic function cannot itself be handed to the engine yet.)
pub fn slot_compare(a: *mut c_void, b: *mut c_void) -> c_int:
    let compare = unsafe { *(a as *const fn(*const u8, *const u8) -> i32) }
    compare(a as *const u8, b as *const u8) as c_int

/// The comparator of a slot whose engine never compares (Trie).
pub fn slot_unordered(a: *const u8, b: *const u8) -> i32: 0
