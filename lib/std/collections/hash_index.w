// std.collections.hash_index — HashIndex[K, V]: a keyed hash index over the
// migrated TommyDS hashdyn engine (docs/stdlib_sourcing_plan.md, Phase 2:
// "node ownership for intrusive engines"). The engine threads intrusive
// nodes through power-of-two bucket lists and resizes as it grows; it never
// allocates a node. The facade owns every node: one heap slot per entry
// holding the node, the key comparator, the key and the value, so an engine
// pointer never aliases a value the facade does not control.
//
// Complexity contract: O(1) average insert, lookup and remove; the engine
// resizes by one power of two at a time.

use std.option
use std.traits
use std.tommyds.defs
use std.tommyds.tommyhashdyn

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_memcpy(dst: *mut u8, src: *const u8, n: i64) -> *mut u8

/// The head of every slot: the engine's node first, so the node pointer
/// the engine hands back IS the slot, then the With key comparator at a
/// fixed offset the C trampoline reads without knowing K or V.
pub type HashSlotHead { node: tommy_node_struct, compare: fn(*const u8, *const u8) -> i32 }

/// One entry: written once by the facade that allocates it, read back
/// exactly once when the key and value transfer out (remove, clear, drop).
pub type HashSlot[K, V] { head: HashSlotHead, key: K, value: V }

/// The one C-ABI comparison the facade registers with the engine: the
/// engine calls it as `cmp(probe, node.data)`; the probe is a slot whose
/// comparator compares its key with the stored slot's key (#1135: a closure
/// written in a generic function cannot itself be handed to the engine).
pub fn hash_slot_compare(probe: *const c_void, data: *const c_void) -> c_int:
    // D63: a callable is not Copy; the slot keeps its comparator, this call
    // observes a free clone of the bare function.
    let compare = unsafe { (*(probe as *const HashSlotHead)).compare.clone() }
    compare(probe as *const u8, data as *const u8) as c_int

/// Keys hash through `Hash.hash_value` and compare through `Eq.eq` (D41).
/// `get` observes (`Option[&V]`), `remove` transfers (`Option[V]`), `insert`
/// of an existing key transfers the previous value out.
/// `probe` is one slot-shaped buffer the lookups reuse: the engine compares
/// a probe against stored slots through the probe's comparator, so every
/// lookup needs a slot holding the comparator and a byte image of the key
/// (never read back as owned). Allocating it once keeps a lookup at the
/// engine's cost plus one hash and one comparison.
pub type HashIndex[K, V] { map: *mut tommy_hashdyn_struct, probe: *mut HashSlot[K, V] }

pub fn HashIndex.new[K: Hash + Eq, V]() -> HashIndex[K, V]:
    let map = unsafe { with_alloc(sizeof[tommy_hashdyn_struct]() as i64) } as *mut tommy_hashdyn_struct
    unsafe { tommy_hashdyn_init(map) }
    let probe = unsafe { with_alloc(sizeof[HashSlot[K, V]]() as i64) } as *mut HashSlot[K, V]
    HashIndex { map: map, probe: probe }

impl[K, V] HashIndex[K, V]:
    pub fn len() -> i32: unsafe { (*self.map).count } as i32
    pub fn is_empty() -> bool: self.len() == 0

    /// Drops every key and value and frees their slots; the engine's
    /// buckets are left to the caller (clear re-initializes, drop frees).
    fn release_all() -> Unit:
        let bucket_max = unsafe { (*self.map).bucket_max } as i64
        var b: i64 = 0
        while b < bucket_max:
            var node = unsafe { *((*self.map).bucket + b as u64) }
            while node as i64 != 0:
                let next = unsafe { (*node).next }
                var slot = node as *mut HashSlot[K, V]
                let stored_key: K = unsafe { move slot.key }
                drop(stored_key)
                let value: V = unsafe { move slot.value }
                drop(value)
                unsafe { with_free(slot as *mut u8) }
                node = next
            b = b + 1

    /// Drops every entry and empties the index.
    pub mut fn clear() -> Unit:
        self.release_all()
        unsafe { tommy_hashdyn_done(self.map) }
        unsafe { tommy_hashdyn_init(self.map) }

    /// An ephemeral cursor over the entries in bucket order.
    pub fn iter() -> HashIndexIter[K, V]:
        HashIndexIter { map: self.map as i64, bucket: -1, node: 0 }

impl[K, V] Drop for HashIndex[K, V]:
    move fn drop():
        self.release_all()
        unsafe { tommy_hashdyn_done(self.map) }
        unsafe { with_free(self.map as *mut u8) }
        unsafe { with_free(self.probe as *mut u8) }

impl[K: Hash + Eq, V] HashIndex[K, V]:
    fn comparator() -> fn(*const u8, *const u8) -> i32:
        (a, b) =>
            let left = unsafe { &(*(a as *const HashSlot[K, V])).key }
            let right = unsafe { &(*(b as *const HashSlot[K, V])).key }
            if left == right: 0 else: 1

    fn hash_of(key: &K) -> c_ulonglong: key.hash_value() as c_ulonglong

    /// The slot holding `key`, or null (the probe's key is a byte image).
    fn find(key: &K) -> *mut HashSlot[K, V]:
        let probe = self.probe
        unsafe { (*probe).head.compare = self.comparator() }
        unsafe { with_memcpy(&raw mut (*probe).key as *mut u8, &raw const *key as *const u8, sizeof[K]() as i64) }
        unsafe { tommy_hashdyn_search(self.map, hash_slot_compare, probe as *const c_void, self.hash_of(key)) } as *mut HashSlot[K, V]

    /// Observes the value stored under `key`.
    pub fn get(key: &K) -> Option[&V]:
        let slot = self.find(key)
        if slot as i64 == 0: None else: Some(unsafe { &(*slot).value })

    pub fn contains(key: &K) -> bool: self.find(key) as i64 != 0

    /// Stores `value` under `key`; an existing entry with an equal key is
    /// replaced and its value transferred back.
    pub mut fn insert(key: K, value: V) -> Option[V]:
        let previous = self.remove(&key)
        let hash = self.hash_of(&key)
        let slot = unsafe { with_alloc(sizeof[HashSlot[K, V]]() as i64) } as *mut HashSlot[K, V]
        let node = tommy_node_struct { next: null, prev: null, data: null, index: 0 }
        unsafe { *slot = HashSlot { head: HashSlotHead { node: node, compare: self.comparator() }, key: key, value: value } }
        unsafe { tommy_hashdyn_insert(self.map, &raw mut (*slot).head.node, slot as *mut c_void, hash) }
        previous

    /// Transfers the value stored under `key` out; the key is dropped.
    pub mut fn remove(key: &K) -> Option[V]:
        var slot = self.find(key)
        if slot as i64 == 0: return None
        unsafe { tommy_hashdyn_remove_existing(self.map, &raw mut (*slot).head.node) }
        let stored_key: K = unsafe { move slot.key }
        drop(stored_key)
        let value: V = unsafe { move slot.value }
        unsafe { with_free(slot as *mut u8) }
        Some(value)

/// One entry seen through a cursor: views of its key and value.
pub type HashEntry[K, V] ephemeral { slot: i64 }

impl[K, V] HashEntry[K, V]:
    pub fn key() -> &K: unsafe { &(*(self.slot as *const HashSlot[K, V])).key }
    pub fn value() -> &V: unsafe { &(*(self.slot as *const HashSlot[K, V])).value }

/// Cursor over a HashIndex; obtain via `index.iter()`. `next()` yields each
/// entry once, in bucket order, then `None`.
pub type HashIndexIter[K, V] ephemeral { map: i64, bucket: i64, node: i64 }

impl[K, V] HashIndexIter[K, V]:
    pub mut fn next() -> Option[HashEntry[K, V]]:
        let map = self.map as *mut tommy_hashdyn_struct
        if self.node != 0:
            self.node = unsafe { (*(self.node as *mut tommy_node_struct)).next } as i64
        let bucket_max = unsafe { (*map).bucket_max } as i64
        while self.node == 0:
            self.bucket = self.bucket + 1
            if self.bucket >= bucket_max: return None
            self.node = unsafe { *((*map).bucket + self.bucket as u64) } as i64
        Some(HashEntry { slot: self.node })
