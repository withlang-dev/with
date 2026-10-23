// std.collections — collection type surface imported by the prelude.
//
// Keep this module intentionally minimal for selfhost compatibility.
// The compiler still owns the lowering/runtime behavior for these
// collection types; this module provides the user-facing names so they
// resolve through normal imports instead of hardcoded sema allowlists.

use std.option
use rt.rt_core
use std.engines.mlib.defs
use std.engines.mlib.facade_shapes
use std.collections.mlib_slot.MlibSlot
use std.collections.mlib_slot.MlibSlotPrefix
use std.collections.mlib_slot.mlib_slot_prefix

/// A growable array. Create with `List.new()`, add with `.push()`,
/// read with `.get()`. Supports iteration via `.iter()`.
pub type List[T]  {
    ptr: *const T,
    len: i64,
    cap: i64,
    // D115 Amendment 1: the elements before `ptr` in the allocation (the
    // head of an owned List comes off by advancing `ptr`, O(1)).
    start: i64,
}


impl[T] List[T]:
    /// §9.7: a small remainder keeps the whole original buffer alive;
    /// `shrink_to_fit` releases the prefix and the spare capacity.
    pub mut fn shrink_to_fit(): with_vec_shrink_to_fit_es((&raw mut self) as *mut u8, sizeof[T]())

    /// D117 (§9.5, §13.3): the expression forms of `[first, ..rest]`. On a
    /// place `first()` and `last()` observe (`Option[&T]`: "is there a first
    /// element?" has a normal answer of no) and `rest()` views; on an owned
    /// receiver (a temporary, `(move xs)`) they take: the element, or the
    /// remainder sharing the buffer (O(1)). The two forms of a name are one
    /// operation, differing only in the ownership of the result.
    pub fn first() -> Option[&T]: if self.len() == 0: None else: Some(&self[0])
    pub move fn first() -> Option[T]:
        match move self:
            [h, ..rest] => Some(h)
            [] => None
    pub fn last() -> Option[&T]: if self.len() == 0: None else: Some(&self[self.len() - 1])
    pub move fn last() -> Option[T]:
        match move self:
            [..init, l] => Some(l)
            [] => None
    pub fn rest() -> []T: if self.len() == 0: self[0..0] else: self[1..self.len()]
    pub move fn rest() -> List[T]:
        match move self:
            [_, ..t] => t
            [] => List.new()

/// Clone for List[T]: produces a deep copy by cloning each element.
impl[T: Clone] Clone for List[T]:
    fn clone() -> Self:
        var out: List[T] = List.new()
        var index: i64 = 0
        while index < self.len():
            let item = self[index]
            comptime if T.is_copy():
                out.push(item)
            else:
                out.push(item.clone())
            index = index + 1
        out

/// An unordered key-value map. Create with `HashMap.new()`,
/// insert with `.insert(key, val)`, read with `.get(key)`.
pub type HashMap[K, V]  {
    ptr: *const i8,
}

/// An unordered set of unique values. Create with `HashSet.new()`.
pub type HashSet[T]  {
    ptr: *const i8,
}

/// Ordered key-value map over the migrated M*LIB B+tree
/// (docs/proposals/stdlib_sourcing_plan.md, Phase 4; #937). Each entry is
/// one facade-owned record holding the key and the value; the engine orders
/// slots it owns (clones of the key, D151) that point back at the entry,
/// through the key comparator (std.collections.mlib_slot). Keys are kept in
/// ascending `Ord` order (D41). O(log n) insert, lookup and remove; in-order
/// traversal O(n). A copy is `.clone()` (the map is a resource).
/// An integer key takes the word shape (D148): the engine's own int64_t,
/// ordered without a callback, holding the entry's address; `words` is that
/// tree and `tree` the slot one, only one of them ever filled.
pub type BTreeMap[K, V] { tree: mlib_slot_tree_s, words: mlib_word_tree_s }

/// One entry: the slot prefix, the key, the value. A probe for a lookup is a
/// `MlibSlot[K]` — the same prefix and the key at the same offset — so the
/// engine compares it like a stored slot.
pub type BTreeEntry[K, V] { prefix: MlibSlotPrefix, key: K, value: V }

/// The word shape's entry: the key and the value, keyed in the engine by the
/// key's word.
pub type BTreeWordEntry[K, V] { key: K, value: V }

/// Ordered set of unique values over the same B+tree: one facade-owned
/// entry per element, the engine's slots pointing back at it.
pub type BTreeSet[T] { tree: mlib_slot_tree_s, words: mlib_word_tree_s }

/// The word shape's set element.
pub type BTreeWordItem[T] { key: T }

pub fn BTreeMap.new[K, V]() -> BTreeMap[K, V]:
    var map: BTreeMap[K, V] = BTreeMap { tree: mlib_slot_tree_s {}, words: mlib_word_tree_s {} }
    unsafe:
        mlib_slot_tree_init(&raw mut map.tree)
        mlib_word_tree_init(&raw mut map.words)
    map

// The engine reads through a mutable pointer (C's `const tree_t` decays to
// the node pointer); a view of the map hands it the same address.
fn btree_handle(tree: &mlib_slot_tree_s) -> *mut mlib_slot_tree_s: &raw const *tree as *mut mlib_slot_tree_s
fn word_handle(words: &mlib_word_tree_s) -> *mut mlib_word_tree_s: &raw const *words as *mut mlib_word_tree_s

// D148's word shape: the integer scalars whose key is the engine's own
// int64_t (`comptime if` instantiates only the branch taken).
fn btree_is_word[K]() -> bool:
    comptime if K.name() == "i64" or K.name() == "u64" or K.name() == "i32" or K.name() == "u32" or K.name() == "i16" or K.name() == "u16" or K.name() == "i8" or K.name() == "u8" or K.name() == "isize" or K.name() == "usize": true
    else: false

// The key's word. An unsigned 64-bit key flips its sign bit, which keeps
// its order under the engine's signed comparison.
fn btree_word[K](key: &K) -> i64:
    comptime if K.name() == "u64" or K.name() == "usize": ((*key as u64) ^ 9223372036854775808) as i64
    else: *key as i64

impl[K: Ord + Clone, V] BTreeMap[K, V]:
    fn comparator() -> fn(*const u8, *const u8) -> i32:
        (a, b) =>
            let left = unsafe { &(*(a as *const MlibSlot[K])).key }
            let right = unsafe { &(*(b as *const MlibSlot[K])).key }
            if left < right: -1 else if left > right: 1 else: 0

    // The engine's clone of a key slot (INIT_SET): the same prefix (its
    // entry pointer with it), the key cloned; CLEAR drops it (dropper).
    fn cloner() -> fn(*const u8) -> *mut u8:
        (p) =>
            let source = unsafe { &(*(p as *const MlibSlot[K])).prefix }
            let prefix = mlib_slot_prefix(source.compare.clone(), source.clone_fn.clone(), source.drop_fn.clone(), source.head.entry as *mut u8)
            let cloned: K = unsafe { (*(p as *const MlibSlot[K])).key.clone() }
            let slot = with_alloc(sizeof[MlibSlot[K]]() as i64) as *mut MlibSlot[K]
            unsafe { *slot = MlibSlot { prefix: prefix, key: cloned } }
            slot as *mut u8

    fn dropper() -> fn(*mut u8) -> Unit:
        (p) =>
            var slot = p as *mut MlibSlot[K]
            let key: K = unsafe { move slot.key }
            drop(key)
            with_free(p)

    fn prefix(entry: *mut u8) -> MlibSlotPrefix:
        let compare = self.comparator()
        let clone_fn = self.cloner()
        let drop_fn = self.dropper()
        mlib_slot_prefix(compare, clone_fn, drop_fn, entry)

    pub fn len() -> isize:
        comptime if btree_is_word[K](): unsafe { mlib_word_tree_size(word_handle(&self.words)) } as isize
        else: unsafe { mlib_slot_tree_size(btree_handle(&self.tree)) } as isize

    pub fn is_empty() -> bool: self.len() == 0

    // The word shape's entry under `key`, or null.
    unsafe fn word_entry(key: &K) -> *mut BTreeWordEntry[K, V]:
        let found = mlib_word_tree_get(word_handle(&self.words), btree_word(key))
        if found as i64 == 0: 0 as *mut BTreeWordEntry[K, V] else: (*found) as *mut BTreeWordEntry[K, V]

    unsafe fn probe(key: &K) -> *mut MlibSlot[K]:
        let probe = with_alloc(sizeof[MlibSlot[K]]() as i64) as *mut MlibSlot[K]
        (*probe).prefix = self.prefix(null)
        with_memcpy(&raw mut (*probe).key as *mut u8, &raw const *key as *const u8, sizeof[K]() as i64)
        probe

    // The engine's slot under `key` (the address of the stored pointer), or null.
    unsafe fn find_slot(key: &K) -> *mut *mut mlib_slot_head:
        let probe = self.probe(key)
        let found = mlib_slot_tree_get(btree_handle(&self.tree), probe as *mut mlib_slot_head)
        with_free(probe as *mut u8)
        found

    unsafe fn find_entry(key: &K) -> *mut BTreeEntry[K, V]:
        let found = self.find_slot(key)
        if found as i64 == 0: 0 as *mut BTreeEntry[K, V] else: (*(*found)).entry as *mut BTreeEntry[K, V]

    pub fn contains(key: &K) -> bool:
        comptime if btree_is_word[K](): unsafe { self.word_entry(key) } as i64 != 0
        else: unsafe { self.find_entry(key) } as i64 != 0

    /// Observes the value under `key`, if any (D22).
    pub fn get(key: &K) -> Option[&V] from self:
        comptime if btree_is_word[K]():
            let entry = unsafe { self.word_entry(key) }
            if entry as i64 == 0: None else: Some(unsafe { &(*entry).value })
        else:
            let entry = unsafe { self.find_entry(key) }
            if entry as i64 == 0: None else: Some(unsafe { &(*entry).value })

    /// Stores `value` under `key`; an equal stored key's entry is replaced
    /// (the stored key and the old value drop).
    pub mut fn insert(key: K, value: V) -> Unit:
        comptime if btree_is_word[K]():
            let word = btree_word(&key)
            let entry = with_alloc(sizeof[BTreeWordEntry[K, V]]() as i64) as *mut BTreeWordEntry[K, V]
            unsafe { *entry = BTreeWordEntry { key: key, value: value } }
            let found = unsafe { mlib_word_tree_get(&raw mut self.words, word) }
            if found as i64 == 0:
                unsafe { mlib_word_tree_set_at(&raw mut self.words, word, entry as *mut c_void) }
                return
            var old = unsafe { *found } as *mut BTreeWordEntry[K, V]
            unsafe { *found = entry as *mut c_void }
            let old_key: K = unsafe { move old.key }
            drop(old_key)
            let old_value: V = unsafe { move old.value }
            drop(old_value)
            with_free(old as *mut u8)
        else:
            let entry = with_alloc(sizeof[BTreeEntry[K, V]]() as i64) as *mut BTreeEntry[K, V]
            unsafe { *entry = BTreeEntry { prefix: self.prefix(entry as *mut u8), key: key, value: value } }
            let found = unsafe { mlib_slot_tree_get(&raw mut self.tree, entry as *mut mlib_slot_head) }
            if found as i64 == 0:
                unsafe { mlib_slot_tree_push(&raw mut self.tree, entry as *mut mlib_slot_head) }
                return
            // The engine's slot keeps its key clone (equal) and points at the new
            // entry; the old entry transfers its key and value out to drop.
            var old = unsafe { (*(*found)).entry } as *mut BTreeEntry[K, V]
            unsafe { (*(*found)).entry = entry as *mut c_void }
            let old_key: K = unsafe { move old.key }
            drop(old_key)
            let old_value: V = unsafe { move old.value }
            drop(old_value)
            with_free(old as *mut u8)

    /// Transfers the value under `key` out, if any; the key drops.
    pub mut fn remove(key: &K) -> Option[V]:
        comptime if btree_is_word[K]():
            var entry = unsafe { self.word_entry(key) }
            if entry as i64 == 0: return None
            assert(unsafe { mlib_word_tree_erase(&raw mut self.words, btree_word(key)) })
            let stored_key: K = unsafe { move entry.key }
            drop(stored_key)
            let value: V = unsafe { move entry.value }
            with_free(entry as *mut u8)
            Some(value)
        else:
            var entry = unsafe { self.find_entry(key) }
            if entry as i64 == 0: return None
            assert(unsafe { mlib_slot_tree_erase(&raw mut self.tree, entry as *mut mlib_slot_head) })
            let stored_key: K = unsafe { move entry.key }
            drop(stored_key)
            let value: V = unsafe { move entry.value }
            with_free(entry as *mut u8)
            Some(value)

    /// Drops every entry; the map is empty afterwards.
    pub mut fn clear() -> Unit:
        self.drop_entries()
        unsafe:
            mlib_slot_tree_reset(&raw mut self.tree)
            mlib_word_tree_reset(&raw mut self.words)

    // Every entry dropped and freed; the engine's own slots are its to clear.
    mut fn drop_entries():
        comptime if btree_is_word[K]():
            var word_cursor = mlib_word_tree_it_s { pair: mlib_word_tree_pair_s {} }
            unsafe { mlib_word_tree_it(&raw mut word_cursor, &raw mut self.words) }
            while not unsafe { mlib_word_tree_end_p(&raw mut word_cursor) }:
                var entry = unsafe { *((*mlib_word_tree_ref(&raw mut word_cursor)).value_ptr) } as *mut BTreeWordEntry[K, V]
                let key: K = unsafe { move entry.key }
                drop(key)
                let value: V = unsafe { move entry.value }
                drop(value)
                with_free(entry as *mut u8)
                unsafe { mlib_word_tree_next(&raw mut word_cursor) }
        else:
            var cursor = mlib_slot_tree_it_s {}
            unsafe { mlib_slot_tree_it(&raw mut cursor, &raw mut self.tree) }
            while not unsafe { mlib_slot_tree_end_p(&raw mut cursor) }:
                var entry = unsafe { (*(*mlib_slot_tree_ref(&raw mut cursor))).entry } as *mut BTreeEntry[K, V]
                let key: K = unsafe { move entry.key }
                drop(key)
                let value: V = unsafe { move entry.value }
                drop(value)
                with_free(entry as *mut u8)
                unsafe { mlib_slot_tree_next(&raw mut cursor) }

    /// Observes the least key's entry, or `None` when empty.
    pub fn first() -> Option[(&K, &V)]:
        if self.len() == 0: return None
        comptime if btree_is_word[K]():
            let entry = unsafe { *mlib_word_tree_min(word_handle(&self.words)) } as *const BTreeWordEntry[K, V]
            Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))
        else:
            let entry = unsafe { (*(*mlib_slot_tree_min(btree_handle(&self.tree)))).entry } as *const BTreeEntry[K, V]
            Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))

    /// Observes the greatest key's entry, or `None` when empty.
    pub fn last() -> Option[(&K, &V)]:
        if self.len() == 0: return None
        comptime if btree_is_word[K]():
            let entry = unsafe { *mlib_word_tree_max(word_handle(&self.words)) } as *const BTreeWordEntry[K, V]
            Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))
        else:
            let entry = unsafe { (*(*mlib_slot_tree_max(btree_handle(&self.tree)))).entry } as *const BTreeEntry[K, V]
            Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))

    // The greatest entry, transferred out (the consuming traversals).
    mut fn take_last() -> Option[(K, V)]:
        if self.len() == 0: return None
        comptime if btree_is_word[K]():
            var entry = unsafe { *mlib_word_tree_max(&raw mut self.words) } as *mut BTreeWordEntry[K, V]
            assert(unsafe { mlib_word_tree_erase(&raw mut self.words, btree_word(&(*entry).key)) })
            let key: K = unsafe { move entry.key }
            let value: V = unsafe { move entry.value }
            with_free(entry as *mut u8)
            Some((key, value))
        else:
            var entry = unsafe { (*(*mlib_slot_tree_max(&raw mut self.tree))).entry } as *mut BTreeEntry[K, V]
            assert(unsafe { mlib_slot_tree_erase(&raw mut self.tree, entry as *mut mlib_slot_head) })
            let key: K = unsafe { move entry.key }
            let value: V = unsafe { move entry.value }
            with_free(entry as *mut u8)
            Some((key, value))

    // D44: traversal observes. Each yields views into the entries, in key order.
    @[iter_of_self]
    pub fn iter() -> BTreeMapIter[K, V]:
        var cursor = mlib_slot_tree_it_s {}
        var word_cursor = mlib_word_tree_it_s { pair: mlib_word_tree_pair_s {} }
        comptime if btree_is_word[K](): unsafe { mlib_word_tree_it(&raw mut word_cursor, word_handle(&self.words)) }
        else: unsafe { mlib_slot_tree_it(&raw mut cursor, btree_handle(&self.tree)) }
        BTreeMapIter { cursor: cursor, word_cursor: word_cursor }

    @[iter_of_self]
    pub fn keys() -> BTreeMapKeys[K, V]: BTreeMapKeys { entries: self.iter() }

    @[iter_of_self]
    pub fn values() -> BTreeMapValues[K, V]: BTreeMapValues { entries: self.iter() }

impl[K, V] Drop for BTreeMap[K, V]:
    move fn drop():
        self.drop_entries()
        unsafe:
            mlib_slot_tree_clear(&raw mut self.tree)
            mlib_word_tree_clear(&raw mut self.words)

impl[K: Ord + Clone, V: Clone] Clone for BTreeMap[K, V]:
    fn clone() -> BTreeMap[K, V]:
        var out: BTreeMap[K, V] = BTreeMap.new()
        for (key, value) in self: out.insert(key.clone(), value.clone())
        out

/// `map.iter()`, and what `for (k, v) in map` walks: each entry as views.
pub type BTreeMapIter[K, V] ephemeral { cursor: mlib_slot_tree_it_s, word_cursor: mlib_word_tree_it_s }

impl[K, V] Iter[(&K, &V)] for BTreeMapIter[K, V]:
    mut fn next() -> Option[(&K, &V)]:
        comptime if btree_is_word[K]():
            if unsafe { mlib_word_tree_end_p(&raw mut self.word_cursor) }: return None
            let entry = unsafe { *((*mlib_word_tree_ref(&raw mut self.word_cursor)).value_ptr) } as *const BTreeWordEntry[K, V]
            unsafe { mlib_word_tree_next(&raw mut self.word_cursor) }
            Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))
        else:
            if unsafe { mlib_slot_tree_end_p(&raw mut self.cursor) }: return None
            let entry = unsafe { (*(*mlib_slot_tree_ref(&raw mut self.cursor))).entry } as *const BTreeEntry[K, V]
            unsafe { mlib_slot_tree_next(&raw mut self.cursor) }
            Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))

/// `map.keys()`: each key as a view, in order.
pub type BTreeMapKeys[K, V] ephemeral { entries: BTreeMapIter[K, V] }

impl[K, V] Iter[&K] for BTreeMapKeys[K, V]:
    mut fn next() -> Option[&K]:
        match self.entries.next():
            Some((k, _)) => Some(k)
            None => None

/// `map.values()`: each value as a view, in key order.
pub type BTreeMapValues[K, V] ephemeral { entries: BTreeMapIter[K, V] }

impl[K, V] Iter[&V] for BTreeMapValues[K, V]:
    mut fn next() -> Option[&V]:
        match self.entries.next():
            Some((_, v)) => Some(v)
            None => None

// §15.4.7 / D61: the `:?` forms of the maps. The compiler calls these for
// every map an f-string formats with `:?`, at any depth; `{k:?}` and `{v:?}`
// are the same recursive formatter, so a map formats the same everywhere.

// `{key: value, key: value}` in key order.
impl[K: Ord + Clone, V] BTreeMap[K, V]:
    fn debug_form() -> str:
        let parts: List[str] = List.with_capacity(self.len())
        for (key, value) in self:
            parts.push(f"{key:?}: {value:?}")
        "{" ++ parts.join(", ") ++ "}"

// `{key: value, key: value}` ordered by the Debug text of the keys: a key
// need not be Ord, and the hash order is seeded — a snapshot or a fixpoint
// would differ run to run. Each key and value is formatted once; the order
// is a stable merge sort of indices, so equal key text falls back to the
// value text and the output is byte-identical for equal maps.
impl[K, V] HashMap[K, V]:
    fn debug_form() -> str:
        let keys: List[str] = List.with_capacity(self.len())
        let values: List[str] = List.with_capacity(self.len())
        for (key, value) in self:
            keys.push(f"{key:?}")
            values.push(f"{value:?}")
        let order = debug_entry_order(&keys, &values)
        let parts: List[str] = List.with_capacity(order.len())
        for i in order:
            parts.push(f"{keys[i]}: {values[i]}")
        "{" ++ parts.join(", ") ++ "}"

// `{elem, elem}` ordered by the Debug text of the elements, for the same
// reason as a HashMap's keys. The set has no traversal of its own: the
// compiler walks its table, formats each element with `:?`, and hands the
// texts here (#1564).
impl[T] HashSet[T]:
    fn debug_form_of(texts: &List[str]) -> str:
        let parts: List[str] = List.with_capacity(texts.len())
        for i in debug_entry_order(texts, texts):
            parts.push(texts[i])
        "{" ++ parts.join(", ") ++ "}"

fn debug_entry_before(keys: &List[str], values: &List[str], a: i64, b: i64) -> bool:
    keys[a] < keys[b] or (keys[a] == keys[b] and values[a] < values[b])

// Bottom-up merge sort of 0..n by (key text, value text): n log n
// comparisons, one scratch buffer, no allocation per comparison.
fn debug_entry_order(keys: &List[str], values: &List[str]) -> List[i64]:
    let n = keys.len()
    let order: List[i64] = List.with_capacity(n)
    let scratch: List[i64] = List.with_capacity(n)
    for i in 0..n:
        order.push(i)
        scratch.push(i)
    var width: isize = 1
    while width < n:
        var lo: isize = 0
        while lo < n:
            let mid = if lo + width < n: lo + width else: n
            let hi = if lo + 2 * width < n: lo + 2 * width else: n
            var a = lo
            var b = mid
            for k in lo..hi:
                if a < mid and (b >= hi or not debug_entry_before(keys, values, order[b], order[a])):
                    scratch[k] = order[a]
                    a = a + 1
                else:
                    scratch[k] = order[b]
                    b = b + 1
            for k in lo..hi:
                order[k] = scratch[k]
            lo = hi
        width = width * 2
    order

pub fn BTreeSet.new[T]() -> BTreeSet[T]:
    var set: BTreeSet[T] = BTreeSet { tree: mlib_slot_tree_s {}, words: mlib_word_tree_s {} }
    unsafe:
        mlib_slot_tree_init(&raw mut set.tree)
        mlib_word_tree_init(&raw mut set.words)
    set

impl[T: Ord + Clone] BTreeSet[T]:
    fn comparator() -> fn(*const u8, *const u8) -> i32:
        (a, b) =>
            let left = unsafe { &(*(a as *const MlibSlot[T])).key }
            let right = unsafe { &(*(b as *const MlibSlot[T])).key }
            if left < right: -1 else if left > right: 1 else: 0

    // The engine's clone of a key slot (INIT_SET): the same prefix (its
    // entry pointer with it), the key cloned; CLEAR drops it (dropper).
    fn cloner() -> fn(*const u8) -> *mut u8:
        (p) =>
            let source = unsafe { &(*(p as *const MlibSlot[T])).prefix }
            let prefix = mlib_slot_prefix(source.compare.clone(), source.clone_fn.clone(), source.drop_fn.clone(), source.head.entry as *mut u8)
            let cloned: T = unsafe { (*(p as *const MlibSlot[T])).key.clone() }
            let slot = with_alloc(sizeof[MlibSlot[T]]() as i64) as *mut MlibSlot[T]
            unsafe { *slot = MlibSlot { prefix: prefix, key: cloned } }
            slot as *mut u8

    fn dropper() -> fn(*mut u8) -> Unit:
        (p) =>
            var slot = p as *mut MlibSlot[T]
            let key: T = unsafe { move slot.key }
            drop(key)
            with_free(p)

    fn prefix(entry: *mut u8) -> MlibSlotPrefix:
        let compare = self.comparator()
        let clone_fn = self.cloner()
        let drop_fn = self.dropper()
        mlib_slot_prefix(compare, clone_fn, drop_fn, entry)

    pub fn len() -> isize:
        comptime if btree_is_word[T](): unsafe { mlib_word_tree_size(word_handle(&self.words)) } as isize
        else: unsafe { mlib_slot_tree_size(btree_handle(&self.tree)) } as isize

    pub fn is_empty() -> bool: self.len() == 0

    // The word shape's item holding `value`, or null.
    unsafe fn word_item(value: &T) -> *mut BTreeWordItem[T]:
        let found = mlib_word_tree_get(word_handle(&self.words), btree_word(value))
        if found as i64 == 0: 0 as *mut BTreeWordItem[T] else: (*found) as *mut BTreeWordItem[T]

    unsafe fn probe(value: &T) -> *mut MlibSlot[T]:
        let probe = with_alloc(sizeof[MlibSlot[T]]() as i64) as *mut MlibSlot[T]
        (*probe).prefix = self.prefix(null)
        with_memcpy(&raw mut (*probe).key as *mut u8, &raw const *value as *const u8, sizeof[T]() as i64)
        probe

    // The facade's entry holding `value`, or null.
    unsafe fn find_entry(value: &T) -> *mut MlibSlot[T]:
        let probe = self.probe(value)
        let found = mlib_slot_tree_get(btree_handle(&self.tree), probe as *mut mlib_slot_head)
        with_free(probe as *mut u8)
        if found as i64 == 0: 0 as *mut MlibSlot[T] else: (*(*found)).entry as *mut MlibSlot[T]

    pub fn contains(value: &T) -> bool:
        comptime if btree_is_word[T](): unsafe { self.word_item(value) } as i64 != 0
        else: unsafe { self.find_entry(value) } as i64 != 0

    /// Stores `value`; an equal stored element keeps its place and the new
    /// one drops.
    pub mut fn insert(value: T) -> Unit:
        comptime if btree_is_word[T]():
            if unsafe { self.word_item(&value) } as i64 != 0:
                drop(value)
                return
            let word = btree_word(&value)
            let item = with_alloc(sizeof[BTreeWordItem[T]]() as i64) as *mut BTreeWordItem[T]
            unsafe { *item = BTreeWordItem { key: value } }
            unsafe { mlib_word_tree_set_at(&raw mut self.words, word, item as *mut c_void) }
        else:
            if unsafe { self.find_entry(&value) } as i64 != 0:
                drop(value)
                return
            let entry = with_alloc(sizeof[MlibSlot[T]]() as i64) as *mut MlibSlot[T]
            unsafe { *entry = MlibSlot { prefix: self.prefix(entry as *mut u8), key: value } }
            unsafe { mlib_slot_tree_push(&raw mut self.tree, entry as *mut mlib_slot_head) }

    /// Removes `value`; true when it was present (the element drops).
    pub mut fn remove(value: &T) -> bool:
        comptime if btree_is_word[T]():
            var item = unsafe { self.word_item(value) }
            if item as i64 == 0: return false
            assert(unsafe { mlib_word_tree_erase(&raw mut self.words, btree_word(value)) })
            let stored: T = unsafe { move item.key }
            drop(stored)
            with_free(item as *mut u8)
            true
        else:
            var entry = unsafe { self.find_entry(value) }
            if entry as i64 == 0: return false
            assert(unsafe { mlib_slot_tree_erase(&raw mut self.tree, entry as *mut mlib_slot_head) })
            let stored: T = unsafe { move entry.key }
            drop(stored)
            with_free(entry as *mut u8)
            true

    /// Drops every element; the set is empty afterwards.
    pub mut fn clear() -> Unit:
        self.drop_entries()
        unsafe:
            mlib_slot_tree_reset(&raw mut self.tree)
            mlib_word_tree_reset(&raw mut self.words)

    mut fn drop_entries():
        comptime if btree_is_word[T]():
            var word_cursor = mlib_word_tree_it_s { pair: mlib_word_tree_pair_s {} }
            unsafe { mlib_word_tree_it(&raw mut word_cursor, &raw mut self.words) }
            while not unsafe { mlib_word_tree_end_p(&raw mut word_cursor) }:
                var item = unsafe { *((*mlib_word_tree_ref(&raw mut word_cursor)).value_ptr) } as *mut BTreeWordItem[T]
                let stored: T = unsafe { move item.key }
                drop(stored)
                with_free(item as *mut u8)
                unsafe { mlib_word_tree_next(&raw mut word_cursor) }
        else:
            var cursor = mlib_slot_tree_it_s {}
            unsafe { mlib_slot_tree_it(&raw mut cursor, &raw mut self.tree) }
            while not unsafe { mlib_slot_tree_end_p(&raw mut cursor) }:
                var entry = unsafe { (*(*mlib_slot_tree_ref(&raw mut cursor))).entry } as *mut MlibSlot[T]
                let stored: T = unsafe { move entry.key }
                drop(stored)
                with_free(entry as *mut u8)
                unsafe { mlib_slot_tree_next(&raw mut cursor) }

    /// The elements, in order, as an owned list of clones.
    pub fn items() -> List[T]:
        let out: List[T] = List.with_capacity(self.len())
        for value in self: out.push(value.clone())
        out

    /// Every element of either set, in order.
    pub fn union(other: &BTreeSet[T]) -> BTreeSet[T]:
        var out: BTreeSet[T] = BTreeSet.new()
        for value in self: out.insert(value.clone())
        for value in other: out.insert(value.clone())
        out

    /// The elements of both sets, in order.
    pub fn intersection(other: &BTreeSet[T]) -> BTreeSet[T]:
        var out: BTreeSet[T] = BTreeSet.new()
        for value in self:
            if other.contains(value): out.insert(value.clone())
        out

    /// The elements of this set `other` lacks, in order.
    pub fn difference(other: &BTreeSet[T]) -> BTreeSet[T]:
        var out: BTreeSet[T] = BTreeSet.new()
        for value in self:
            if not other.contains(value): out.insert(value.clone())
        out

    /// D44: traversal observes. Each element as a view, in order.
    @[iter_of_self]
    pub fn iter() -> BTreeSetIter[T]:
        var cursor = mlib_slot_tree_it_s {}
        var word_cursor = mlib_word_tree_it_s { pair: mlib_word_tree_pair_s {} }
        comptime if btree_is_word[T](): unsafe { mlib_word_tree_it(&raw mut word_cursor, word_handle(&self.words)) }
        else: unsafe { mlib_slot_tree_it(&raw mut cursor, btree_handle(&self.tree)) }
        BTreeSetIter { cursor: cursor, word_cursor: word_cursor }

impl[T] Drop for BTreeSet[T]:
    move fn drop():
        self.drop_entries()
        unsafe:
            mlib_slot_tree_clear(&raw mut self.tree)
            mlib_word_tree_clear(&raw mut self.words)

impl[T: Ord + Clone] Clone for BTreeSet[T]:
    fn clone() -> BTreeSet[T]:
        var out: BTreeSet[T] = BTreeSet.new()
        for value in self: out.insert(value.clone())
        out

/// `set.iter()`, and what `for x in set` walks: each element as a view.
pub type BTreeSetIter[T] ephemeral { cursor: mlib_slot_tree_it_s, word_cursor: mlib_word_tree_it_s }

impl[T] Iter[&T] for BTreeSetIter[T]:
    mut fn next() -> Option[&T]:
        comptime if btree_is_word[T]():
            if unsafe { mlib_word_tree_end_p(&raw mut self.word_cursor) }: return None
            let item = unsafe { *((*mlib_word_tree_ref(&raw mut self.word_cursor)).value_ptr) } as *const BTreeWordItem[T]
            unsafe { mlib_word_tree_next(&raw mut self.word_cursor) }
            Some(unsafe { &(*item).key })
        else:
            if unsafe { mlib_slot_tree_end_p(&raw mut self.cursor) }: return None
            let entry = unsafe { (*(*mlib_slot_tree_ref(&raw mut self.cursor))).entry } as *const MlibSlot[T]
            unsafe { mlib_slot_tree_next(&raw mut self.cursor) }
            Some(unsafe { &(*entry).key })

/// Type-safe generational handle into a SlotMap[T].
/// Handles are Copy and carry their owner element type at compile time, so a
/// Handle[Texture] cannot be used with a SlotMap[Mesh].
pub type Handle[T] {
    pub index: u32,
    pub generation: u32,
}

impl[T] Copy for Handle[T]

/// Generational dense-ish storage for long-lived relationships.
/// Runtime storage is compiler-backed like List and HashMap.
pub type SlotMap[T] {
    ptr: *const i8,
}

/// Scoped mutable slot handle returned by SlotMap.slot/get_disjoint.
/// Use `.get()` / `.set(value)` inside the `with` block, matching ListSlot.
pub type SlotMapSlot[T] ephemeral {
    map_ptr: i64,
    index: u32,
    generation: u32,
}

/// Memory ordering for atomic operations.
pub enum Order: i32:
    Relaxed = 0
    Acquire = 1
    Release = 2
    AcqRel = 3
    SeqCst = 4

impl Copy for Order

/// Atomic memory fence. Enforces ordering without an associated operation.
pub fn fence(order: Order) -> Unit:
    // Compiler intrinsic — body is replaced by MIR_INTRINSIC_ATOMIC_FENCE
    0

/// Lock-free atomic operations on integer types.
/// Create with `Atomic.new(0)`, read with `.load(.acquire)`,
/// write with `.store(val, .release)`.
pub type Atomic[T]  {
    val: T,
}

// ── Scoped access ────────────────────────────────────────────────

/// Scoped handle to a single List element (docs/mut.md Rev 8 §10).
/// Obtain via `vec.slot(index)`. Use with `with`:
///   with xs.slot(i) as mut s:
///       let v = s.get()
///       s.set(v + 1)
pub type ListSlot[T] ephemeral { data_ptr: i64, index: i64 }

/// Iterator yielding ListSlot[T] handles for in-place element mutation (§19.5).
/// Obtain via `vec.iter_place()`. Each `.next()` returns `Option[ListSlot[T]]`.
pub type ListIterPlace[T] ephemeral { data_ptr: i64, len: i64, idx: i64 }

/// Scoped handle to a HashMap entry (docs/mut.md Rev 8 §10).
/// Obtain via `map.entry(key)`. Use with `with`:
///   with map.entry(k) as mut e:
///       e.or_insert(default)
pub type HashMapEntry[K, V] ephemeral { map_ptr: i64, key: K }

// ── Iterators ─────────────────────────────────────────────────────

/// The observing iterator over a `List[T]` (§13.1, #2220 step 2): a view of
/// the list and a position, whose `next()` yields `&T` through the element
/// place — bounds-checked by `len()` and `xs[i]`, no raw address. A Copy
/// element reads through the view where a value is demanded (D22, D139),
/// so `for x in xs.iter()`, `map(it * 2)` and `filter(it % 2 == 1)` see
/// the value; an owning element is observed, never copied (§2.3).
pub type ListIter[T] ephemeral { list: &List[T], idx: isize }

impl[T] List[T]:
    /// The same iterator under the name the #2145 rewrite used; every
    /// `iter()` now yields views.
    pub fn iter_ref() -> ListIter[T]: self.iter()

/// Borrow-iteration capability for allocation-backed collection types
/// (D33 naming: formerly misnamed `IntoIter`).
/// §13.2: the borrow an iterator registers on its receiver is SHARED, so
/// constructing one only reads the collection — a `&List` parameter iterates.
/// (A trait method's receiver is explicit: plain `fn` in a trait declares a
/// static method, per the parser's trait-impl receiver rule.)
pub trait Iterable[T]:
    fn iter(self: &Self) -> ListIter[T]

// Iterable for List: the observing iterator over the elements, a view of
// the list at position 0 (the trait impl is the one definition; an
// inherent twin of the same name would register twice, D65).
impl[T] Iterable[T] for List[T]:
    @[iter_of_self]
    fn iter() -> ListIter[T]: ListIter { list: self, idx: 0 }

/// A slice's `iter()` (D142, §13.1): the view iterator a List has, over the
/// slice's elements; `next()` yields `&T` through the element place. The
/// compiler resolves `s.iter()` on a `[]T` here (no `impl` can name a slice).
pub type SliceIter[T] ephemeral { data: []T, idx: isize }

impl[T] Iter[&T] for SliceIter[T]:
    mut fn next() -> Option[&T]:
        if self.idx >= self.data.len(): return None
        let i = self.idx
        self.idx += 1
        &self.data[i]

pub fn slice_iter[T](s: []T) -> SliceIter[T]: SliceIter { data: s, idx: 0 }

/// A range's `iter()` (#2544, §4.7, §13.5): counts from `start` up to `end`
/// (through it for `..=`); `next()` yields the values. The compiler
/// resolves `r.iter()`, and a range on the left of `|>`, here; `for` keeps
/// its counter loop.
pub type RangeIter[T] { cur: T, end: T, inclusive: bool, done: bool }

impl[T: One + Ord] Iter[T] for RangeIter[T]:
    mut fn next() -> Option[T]:
        if self.done: return None
        if self.inclusive:
            if self.cur > self.end: return None
            if self.cur == self.end: self.done = true
        else if self.cur >= self.end:
            return None
        let v = self.cur
        self.cur = self.cur + T.one()
        v

pub fn range_iter[T](r: Range[T]) -> RangeIter[T]: RangeIter { cur: r.start, end: r.end, inclusive: false, done: false }
pub fn range_iter_inclusive[T](r: RangeInclusive[T]) -> RangeIter[T]: RangeIter { cur: r.start, end: r.end, inclusive: true, done: false }

/// Each element with its index (§13.5): `for (i, x) in xs.enumerate():`.
impl[T] List[T]:
    // D100 (§18.3): List's fields are private to std. The buffer's address,
    // for a C call or a runtime helper; reading through it is `unsafe`.
    pub fn as_ptr() -> *const T: self.ptr
    pub fn as_mut_ptr() -> *mut T: self.ptr as *mut T
    // How many elements the buffer holds before it grows. A literal that
    // lives in the frame or in static data owns no buffer (capacity 0 in
    // the header, §4.3c): it holds exactly its elements.
    pub fn capacity() -> i64: if self.cap == 0: self.len else: self.cap

    // The result type is the body's: over elements that own something
    // `iter()` yields views (#2145), so the pairs hold `&T`.
    fn enumerate(): self.iter() |> enumerate()

/// Consuming iterator over List[T] (§13, D33). Obtain via `vec.into_iter()`:
/// the List moves into the iterator and each `.next()` moves one element out.
/// Dropping the iterator early (break, `?`, return) releases the un-yielded
/// tail and the buffer through the owned List's ordinary drop.
pub type ListIntoIter[T] { list: List[T] }

/// Consuming-iteration capability (§13, D33): the collection moves in,
/// elements move out. The loop-shaped `remove` — access observes,
/// transfer is explicit (D27).
pub trait IntoIter[T]:
    move fn into_iter() -> ListIntoIter[T]

impl[T] IntoIter[T] for List[T]:
    move fn into_iter() -> ListIntoIter[T]: ListIntoIter { list: self }

impl[T] Iter[T] for ListIntoIter[T]:
    // remove(0) is D27's proven element transfer, and the runtime takes the
    // head by advancing the buffer's start (D115), O(1) per element (#938).
    mut fn next() -> Option[T]:
        if self.list.len() == 0: return None
        self.list.remove(0)

// ── Map traversal (D44) ───────────────────────────────────────────
// The observing traversals of a keyed map: concrete ephemeral structs over a
// view of the map, whose items are views into its storage. Nothing is copied
// out (§2.3). A HashMap or HashSet is walked through its entry slots in
// insertion order (D96), skipping removed entries; a BTreeMap walks its
// engine's cursor (BTreeMapIter).

enum MapSource[K, V] ephemeral:
    Hash(&HashMap[K, V])

impl[K, V] MapSource[K, V]:
    // The first live position at or after `at`, or -1 at the end.
    fn live_from(at: i64) -> i64:
        match self:
            .Hash(m) =>
                var slot = at
                while slot < m.slot_count():
                    if m.slot_live(slot): return slot
                    slot = slot + 1
                -1

    fn key_at(at: i64) -> &K:
        match self:
            .Hash(m) => m.slot_key(at)

    fn value_at(at: i64) -> &V:
        match self:
            .Hash(m) => m.slot_value(at)

/// `map.iter()`, and what `for (k, v) in map` walks: each entry as views.
pub type MapIter[K, V] ephemeral { source: MapSource[K, V], at: i64 }

/// `map.keys()`: each key as a view.
pub type MapKeys[K, V] ephemeral { source: MapSource[K, V], at: i64 }

/// `map.values()`: each value as a view.
pub type MapValues[K, V] ephemeral { source: MapSource[K, V], at: i64 }

impl[K, V] Iter[(&K, &V)] for MapIter[K, V]:
    mut fn next() -> Option[(&K, &V)]:
        let slot = self.source.live_from(self.at)
        if slot < 0: return None
        self.at = slot + 1
        Some((self.source.key_at(slot), self.source.value_at(slot)))

impl[K, V] Iter[&K] for MapKeys[K, V]:
    mut fn next() -> Option[&K]:
        let slot = self.source.live_from(self.at)
        if slot < 0: return None
        self.at = slot + 1
        Some(self.source.key_at(slot))

impl[K, V] Iter[&V] for MapValues[K, V]:
    mut fn next() -> Option[&V]:
        let slot = self.source.live_from(self.at)
        if slot < 0: return None
        self.at = slot + 1
        Some(self.source.value_at(slot))

impl[K, V] HashMap[K, V]:
    @[iter_of_self]
    pub fn iter() -> MapIter[K, V]: MapIter { source: .Hash(self), at: 0 }

    @[iter_of_self]
    pub fn keys() -> MapKeys[K, V]: MapKeys { source: .Hash(self), at: 0 }

    @[iter_of_self]
    pub fn values() -> MapValues[K, V]: MapValues { source: .Hash(self), at: 0 }

// The consuming traversals (D44): each entry moves out of the map once.
// The entries move out together, last first, so each step pops the next in
// the map's order (insertion order for a HashMap, key order for a BTreeMap);
// the ones never yielded drop with the iterator.

/// `map.into_iter()`: each entry, moved out; the map is consumed.
pub type MapIntoIter[K, V] { entries: List[(K, V)] }

/// `map.into_keys()`: each key, moved out; the values are dropped.
pub type MapIntoKeys[K, V] { entries: MapIntoIter[K, V] }

/// `map.into_values()`: each value, moved out; the keys are dropped.
pub type MapIntoValues[K, V] { entries: MapIntoIter[K, V] }

/// `map.drain()`: each entry, moved out; the map remains, empty.
pub type MapDrain[K, V] { entries: MapIntoIter[K, V] }

impl[K, V] Iter[(K, V)] for MapIntoIter[K, V]:
    mut fn next() -> Option[(K, V)]: self.entries.pop()

impl[K, V] Iter[K] for MapIntoKeys[K, V]:
    mut fn next() -> Option[K]:
        match self.entries.next():
            Some((key, _)) => Some(key)
            None => None

impl[K, V] Iter[V] for MapIntoValues[K, V]:
    mut fn next() -> Option[V]:
        match self.entries.next():
            Some((_, value)) => Some(value)
            None => None

impl[K, V] Iter[(K, V)] for MapDrain[K, V]:
    mut fn next() -> Option[(K, V)]: self.entries.next()

impl[K, V] HashMap[K, V]:
    // Every entry, moved out, last first; the table is left empty.
    mut fn take_reversed() -> MapIntoIter[K, V]:
        var reversed: List[(K, V)] = List.with_capacity(self.len())
        var slot = self.slot_count() - 1
        while slot >= 0:
            if self.slot_live(slot): reversed.push(self.slot_take(slot))
            slot = slot - 1
        self.clear()
        MapIntoIter { entries: reversed }

    pub move fn into_iter() -> MapIntoIter[K, V]:
        var map = self
        map.take_reversed()

    pub move fn into_keys() -> MapIntoKeys[K, V]: MapIntoKeys { entries: self.into_iter() }

    pub move fn into_values() -> MapIntoValues[K, V]: MapIntoValues { entries: self.into_iter() }

    pub mut fn drain() -> MapDrain[K, V]: MapDrain { entries: self.take_reversed() }

impl[K: Ord + Clone, V] BTreeMap[K, V]:
    // Every entry, moved out, last first; the map is left empty.
    mut fn take_reversed() -> MapIntoIter[K, V]:
        var reversed: List[(K, V)] = List.with_capacity(self.len())
        while true:
            match self.take_last():
                Some(entry) => reversed.push(entry)
                None => break
        MapIntoIter { entries: reversed }

    pub move fn into_iter() -> MapIntoIter[K, V]:
        var map = self
        map.take_reversed()

    pub move fn into_keys() -> MapIntoKeys[K, V]: MapIntoKeys { entries: self.into_iter() }

    pub move fn into_values() -> MapIntoValues[K, V]: MapIntoValues { entries: self.into_iter() }

    pub mut fn drain() -> MapDrain[K, V]: MapDrain { entries: self.take_reversed() }

/// `set.iter()`, and what `for x in set` walks: each element as a view.
pub type SetIter[T] ephemeral { set: &HashSet[T], at: i64 }

impl[T] Iter[&T] for SetIter[T]:
    mut fn next() -> Option[&T]:
        while self.at < self.set.slot_count():
            let slot = self.at
            self.at = slot + 1
            if self.set.slot_live(slot): return Some(self.set.slot_key(slot))
        None

impl[T] HashSet[T]:
    @[iter_of_self]
    pub fn iter() -> SetIter[T]: SetIter { set: self, at: 0 }

/// Lazy iterator adapter produced by `.map(f)`.
pub type MappedIter[I, T, U] ephemeral { iter: I, f: fn(T) -> U }

/// Lazy iterator adapter produced by `.filter(pred)`.
pub type FilterIter[I, T] ephemeral { iter: I, pred: fn(T) -> bool }

/// Lazy iterator adapter produced by `.filter_map(f)`.
pub type FilterMapIter[I, T, U] ephemeral { iter: I, f: fn(T) -> Option[U] }

/// Lazy iterator adapter produced by `.take(n)`.
pub type TakeIter[I, T] ephemeral { iter: I, remaining: i64 }

/// Lazy iterator adapter produced by `.drop(n)`.
pub type DropIter[I, T] ephemeral { iter: I, remaining: i64 }

/// Lazy iterator adapter produced by `.take_while(pred)`.
pub type TakeWhileIter[I, T] ephemeral { iter: I, pred: fn(T) -> bool, done: bool }

/// Lazy iterator adapter produced by `.drop_while(pred)`.
pub type DropWhileIter[I, T] ephemeral { iter: I, pred: fn(T) -> bool, dropping: bool }

/// Lazy iterator adapter produced by `.zip(other)`.
pub type ZipIter[A, B, T, U] ephemeral { left: A, right: B }

/// Lazy iterator adapter produced by `.enumerate()`.
pub type EnumerateIter[I, T] ephemeral { iter: I, idx: isize }

/// Lazy iterator adapter produced by `.chain(other)`.
pub type ChainIter[A, B, T] ephemeral { left: A, right: B, use_right: bool }

/// Lazy iterator adapter produced by `.zip_with(other, f)`.
pub type ZipWithIter[A, B, T, U, V] ephemeral { left: A, right: B, f: fn(T, U) -> V }

/// Lazy iterator adapter produced by `.step_by(n)`.
pub type StepByIter[I, T] ephemeral { iter: I, step: i64, first: bool }

/// Lazy iterator adapter produced by `.flat_map(f)`.
pub type FlatMapIter[I, C, J, T, U] ephemeral {
    iter: I,
    f: fn(T) -> C,
    current: J,
    has_current: bool,
}

impl[T] Iter[&T] for ListIter[T]:
    // The tail is the Option (D103). The return stays written until a
    // generic impl takes it from the trait (D140, #2531).
    mut fn next() -> Option[&T]:
        if self.idx >= self.list.len(): return None
        let i = self.idx
        self.idx += 1
        &self.list[i]

// #2152 (§13.1, §13.5): every adapter is an iterator, so a `for` steps
// through it. Each `next` is the adapter's own.
impl[I, T] Iter[T] for FilterIter[I, T]:
    mut fn next() -> Option[T]: self.next()

impl[I, T, U] Iter[U] for MappedIter[I, T, U]:
    mut fn next() -> Option[U]: self.next()

impl[I, T, U] Iter[U] for FilterMapIter[I, T, U]:
    mut fn next() -> Option[U]: self.next()

impl[I, T] Iter[T] for TakeIter[I, T]:
    mut fn next() -> Option[T]: self.next()

impl[I, T] Iter[T] for DropIter[I, T]:
    mut fn next() -> Option[T]: self.next()

impl[I, T] Iter[T] for TakeWhileIter[I, T]:
    mut fn next() -> Option[T]: self.next()

impl[I, T] Iter[T] for DropWhileIter[I, T]:
    mut fn next() -> Option[T]: self.next()

impl[A, B, T, U] Iter[(T, U)] for ZipIter[A, B, T, U]:
    mut fn next() -> Option[(T, U)]: self.next()

impl[I, T] Iter[(isize, T)] for EnumerateIter[I, T]:
    mut fn next() -> Option[(isize, T)]: self.next()

impl[A, B, T] Iter[T] for ChainIter[A, B, T]:
    mut fn next() -> Option[T]: self.next()

impl[I, T] Iter[T] for StepByIter[I, T]:
    mut fn next() -> Option[T]: self.next()

/// Index specification for multi-dimensional indexing.
/// Used by the MultiIndex trait. kind: 0=scalar, 1=slice, 2=ellipsis, 3=newaxis.
pub type IndexSpec {
    pub kind: i32,
    pub start: i64,
    pub stop: i64,
    pub step: i64,
    pub has_start: bool,
    pub has_stop: bool,
    pub has_step: bool,
}

// §13.3 (#1746): `it.collect[List]()` on any Iter[T] implementor, the one
// adapter that builds a collection, so it lives with List rather than in
// std.traits (which the core prelude, List-less, also loads).
/// `it.collect[List]()`: every element, in order.
pub fn iter_collect[T, I: Iter[T]](iter: I) -> List[T]:
    var i = iter
    var out: List[T] = List.new()
    while true:
        match i.next():
            None => break
            Some(x) => out.push(x)
    out

/// `it.collect[List]()` over an iterator of views (D111/D22 §6.2): the List
/// stores the values, so each `&T` element meets the store by a copy — the
/// compiler dispatches a view-element collect here rather than to
/// `iter_collect` building a `List[&T]` no spelling can name.
pub fn iter_collect_views[T, I: Iter[&T]](iter: I) -> List[T]:
    var i = iter
    var out: List[T] = List.new()
    while true:
        match i.next():
            None => break
            Some(x) => out.push(x)
    out

// #2220 step 2 (§13.3): the terminal operations over any Iter[T]
// implementor, as With bodies. Each has a `_views` twin over an iterator of
// views (`ListIter` yields `&T`): a Copy value reads through the view where
// the body demands a value (D22, D139), so the twin's result holds values.
/// `it.collect[HashSet]()`.
pub fn iter_collect_hashset[T: Key, I: Iter[T]](iter: I) -> HashSet[T]:
    var i = iter
    var out: HashSet[T] = HashSet.new()
    while true:
        match i.next():
            None => break
            Some(x) => out.insert(x)
    out

pub fn iter_collect_hashset_views[T: Key, I: Iter[&T]](iter: I) -> HashSet[T]:
    var i = iter
    var out: HashSet[T] = HashSet.new()
    while true:
        match i.next():
            None => break
            Some(x) => out.insert(x)
    out

/// `it.collect[BTreeSet]()`.
pub fn iter_collect_btreeset[T: Ord, I: Iter[T]](iter: I) -> BTreeSet[T]:
    var i = iter
    var out: BTreeSet[T] = BTreeSet.new()
    while true:
        match i.next():
            None => break
            Some(x) => out.insert(x)
    out

pub fn iter_collect_btreeset_views[T: Ord, I: Iter[&T]](iter: I) -> BTreeSet[T]:
    var i = iter
    var out: BTreeSet[T] = BTreeSet.new()
    while true:
        match i.next():
            None => break
            Some(x) => out.insert(x)
    out

/// `it.collect[List]()` over `(A, &B)` pairs (`enumerate()` over views):
/// the List stores `(A, B)` pairs, each Copy view read through (D22 §6.2).
pub fn iter_collect_pair_views[A, B, I: Iter[(A, &B)]](iter: I) -> List[(A, B)]:
    var i = iter
    var out: List[(A, B)] = List.new()
    while true:
        match i.next():
            None => break
            Some(p) => out.push((p.0, p.1))
    out

/// `it.collect[HashMap]()` over `(K, V)` pairs: each pair stored, a later
/// key replacing an earlier one.
pub fn iter_collect_hashmap[K: Key, V, I: Iter[(K, V)]](iter: I) -> HashMap[K, V]:
    var i = iter
    var out: HashMap[K, V] = HashMap.new()
    while true:
        match i.next():
            None => break
            Some(p) => out.insert(p.0, p.1)
    out

pub fn iter_collect_hashmap_views[K: Key, V, I: Iter[&(K, V)]](iter: I) -> HashMap[K, V]:
    var i = iter
    var out: HashMap[K, V] = HashMap.new()
    while true:
        match i.next():
            None => break
            Some(p) => out.insert(p.0, p.1)
    out

/// `it.collect[BTreeMap]()` over `(K, V)` pairs, in key order.
pub fn iter_collect_btreemap[K: Ord, V, I: Iter[(K, V)]](iter: I) -> BTreeMap[K, V]:
    var i = iter
    var out: BTreeMap[K, V] = BTreeMap.new()
    while true:
        match i.next():
            None => break
            Some(p) => out.insert(p.0, p.1)
    out

pub fn iter_collect_btreemap_views[K: Ord, V, I: Iter[&(K, V)]](iter: I) -> BTreeMap[K, V]:
    var i = iter
    var out: BTreeMap[K, V] = BTreeMap.new()
    while true:
        match i.next():
            None => break
            Some(p) => out.insert(p.0, p.1)
    out

/// `it.flat_map(f)` where `f` builds a collection (`s.split(" ")` is a
/// `List[str]`): each one moves in and its elements move out (IntoIter).
/// `f` that yields an iterator is std.traits's FlatMapped.
/// `it.flat_map(f)`: each element through `f`, which yields an iterator,
/// those iterators' elements in order.
// `current` holds the iterator being drained, or nothing: a List of at most
// one, moved out to advance and moved back while it has more (an `Option`
// payload matched out of a field is a copy today, #2541).
pub type FlatMapped[T, U, C, I] { inner: I, f: fn(T) -> C, current: List[C] }

impl[T, U, C: Iter[U], I: Iter[T]] Iter[U] for FlatMapped[T, U, C, I]:
    mut fn next() -> Option[U]:
        loop:
            match self.current.pop():
                Some(c) =>
                    var cur = c
                    match cur.next():
                        Some(x) =>
                            self.current.push(cur)
                            return Some(x)
                        None => ()
                None =>
                    match self.inner.next():
                        None => return None
                        Some(x) => self.current.push((self.f)(x))

pub fn iter_flat_map[T, U, C: Iter[U], I: Iter[T]](iter: I, f: fn(T) -> C) -> FlatMapped[T, U, C, I]:
    let none: List[C] = List.new()
    FlatMapped { inner: iter, f, current: none }

// The pending elements are the current collection's consuming iterator,
// a field mutated in place (an `Option` payload matched out of a field is a
// copy today, #2541).
pub type FlatMappedInto[T, U, C, I] { inner: I, f: fn(T) -> C, pending: ListIntoIter[U] }

impl[T, U, C: IntoIter[U], I: Iter[T]] Iter[U] for FlatMappedInto[T, U, C, I]:
    mut fn next() -> Option[U]:
        loop:
            match self.pending.next():
                Some(x) => return Some(x)
                None =>
                    match self.inner.next():
                        None => return None
                        Some(x) => self.pending = (self.f)(x).into_iter()

pub fn iter_flat_map_into[T, U, C: IntoIter[U], I: Iter[T]](iter: I, f: fn(T) -> C) -> FlatMappedInto[T, U, C, I]:
    let none: List[U] = List.new()
    FlatMappedInto { inner: iter, f, pending: none.into_iter() }

/// `it.sum()`: the elements added up from `T.default()`.
pub fn iter_sum[T: Default, I: Iter[T]](iter: I) -> T:
    var i = iter
    var acc = T.default()
    while true:
        match i.next():
            None => break
            Some(x) => acc = acc + x
    acc

pub fn iter_sum_views[T: Default, I: Iter[&T]](iter: I) -> T:
    var i = iter
    var acc = T.default()
    while true:
        match i.next():
            None => break
            Some(x) => acc = acc + x
    acc

/// `it.product()`: the elements multiplied up from `T.one()`.
pub fn iter_product[T: One, I: Iter[T]](iter: I) -> T:
    var i = iter
    var acc = T.one()
    while true:
        match i.next():
            None => break
            Some(x) => acc = acc * x
    acc

pub fn iter_product_views[T: One, I: Iter[&T]](iter: I) -> T:
    var i = iter
    var acc = T.one()
    while true:
        match i.next():
            None => break
            Some(x) => acc = acc * x
    acc

/// `it.min()` / `it.max()`: the least / greatest element, `None` when empty;
/// the first of equals wins.
pub fn iter_min[T: Ord, I: Iter[T]](iter: I) -> Option[T]:
    var i = iter
    var best: Option[T] = None
    while true:
        match i.next():
            None => break
            Some(x) =>
                match best:
                    None => best = Some(x)
                    Some(b) => if x.cmp(&b) < 0: best = Some(x)
    best

pub fn iter_min_views[T: Ord, I: Iter[&T]](iter: I) -> Option[T]:
    var i = iter
    var best: Option[T] = None
    while true:
        match i.next():
            None => break
            Some(x) =>
                match best:
                    None => best = Some(x)
                    Some(b) => if x.cmp(&b) < 0: best = Some(x)
    best

pub fn iter_max[T: Ord, I: Iter[T]](iter: I) -> Option[T]:
    var i = iter
    var best: Option[T] = None
    while true:
        match i.next():
            None => break
            Some(x) =>
                match best:
                    None => best = Some(x)
                    Some(b) => if x.cmp(&b) > 0: best = Some(x)
    best

pub fn iter_max_views[T: Ord, I: Iter[&T]](iter: I) -> Option[T]:
    var i = iter
    var best: Option[T] = None
    while true:
        match i.next():
            None => break
            Some(x) =>
                match best:
                    None => best = Some(x)
                    Some(b) => if x.cmp(&b) > 0: best = Some(x)
    best

/// `it.min_by(f)` / `it.max_by(f)`: by a comparison `f(a, b)` that is
/// negative, zero or positive as `a` is less than, equal to or greater
/// than `b`; the first of equals wins.
pub fn iter_min_by[T, I: Iter[T]](iter: I, f: fn(&T, &T) -> i32) -> Option[T]:
    var i = iter
    var best: Option[T] = None
    while true:
        match i.next():
            None => break
            Some(x) =>
                match best:
                    None => best = Some(x)
                    Some(b) => if f(&x, &b) < 0: best = Some(x)
    best

// Over views of Copy values the comparator takes the values (D111: a value
// has no identity, so it is passed by copy; `cmp(a: i32, b: i32)` is how
// one is written).
pub fn iter_min_by_views[T, I: Iter[&T]](iter: I, f: fn(T, T) -> i32) -> Option[T]:
    var i = iter
    var best: Option[T] = None
    while true:
        match i.next():
            None => break
            Some(x) =>
                match best:
                    None => best = Some(x)
                    Some(b) => if f(x, b) < 0: best = Some(x)
    best

pub fn iter_max_by[T, I: Iter[T]](iter: I, f: fn(&T, &T) -> i32) -> Option[T]:
    var i = iter
    var best: Option[T] = None
    while true:
        match i.next():
            None => break
            Some(x) =>
                match best:
                    None => best = Some(x)
                    Some(b) => if f(&x, &b) > 0: best = Some(x)
    best

pub fn iter_max_by_views[T, I: Iter[&T]](iter: I, f: fn(T, T) -> i32) -> Option[T]:
    var i = iter
    var best: Option[T] = None
    while true:
        match i.next():
            None => break
            Some(x) =>
                match best:
                    None => best = Some(x)
                    Some(b) => if f(x, b) > 0: best = Some(x)
    best

/// `it.reduce(f)`: `f` folded over the elements from the first, `None` when
/// empty.
pub fn iter_reduce[T, I: Iter[T]](iter: I, f: fn(T, T) -> T) -> Option[T]:
    var i = iter
    var acc: Option[T] = None
    while true:
        match i.next():
            None => break
            Some(x) =>
                match acc:
                    None => acc = Some(x)
                    Some(a) => acc = Some(f(a, x))
    acc

pub fn iter_reduce_views[T, I: Iter[&T]](iter: I, f: fn(T, T) -> T) -> Option[T]:
    var i = iter
    var acc: Option[T] = None
    while true:
        match i.next():
            None => break
            Some(x) =>
                match acc:
                    None => acc = Some(x)
                    Some(a) => acc = Some(f(a, x))
    acc

/// `it.partition(p)`: the elements for which `p` holds, then the rest.
pub fn iter_partition[T, I: Iter[T]](iter: I, pred: fn(&T) -> bool) -> (List[T], List[T]):
    var i = iter
    var yes: List[T] = List.new()
    var no: List[T] = List.new()
    while true:
        match i.next():
            None => break
            Some(x) =>
                if pred(&x): yes.push(x)
                else: no.push(x)
    (yes, no)

pub fn iter_partition_views[T, I: Iter[&T]](iter: I, pred: fn(&T) -> bool) -> (List[T], List[T]):
    var i = iter
    var yes: List[T] = List.new()
    var no: List[T] = List.new()
    while true:
        match i.next():
            None => break
            Some(x) =>
                if pred(x): yes.push(x)
                else: no.push(x)
    (yes, no)

/// `it.unzip()`: the pairs' firsts and seconds as two Lists.
pub fn iter_unzip[A, B, I: Iter[(A, B)]](iter: I) -> (List[A], List[B]):
    var i = iter
    var firsts: List[A] = List.new()
    var seconds: List[B] = List.new()
    while true:
        match i.next():
            None => break
            Some(pair) =>
                firsts.push(pair.0)
                seconds.push(pair.1)
    (firsts, seconds)

/// `it.unzip()` over `(&A, &B)` pairs (a zip of two view iterators): the
/// Lists store the values, each Copy view read through (D22 §6.2).
pub fn iter_unzip_views[A, B, I: Iter[(&A, &B)]](iter: I) -> (List[A], List[B]):
    var i = iter
    var firsts: List[A] = List.new()
    var seconds: List[B] = List.new()
    while true:
        match i.next():
            None => break
            Some(pair) =>
                firsts.push(pair.0)
                seconds.push(pair.1)
    (firsts, seconds)


