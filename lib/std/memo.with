// std.memo — a read-path cache (D172, §19.1).
//
// `Interior[T]` is the compiler-known marker: its contents may change
// through a shared view. The compiler assumes nothing inside it is
// unchanged across a call, on every backend. Constructing or reaching
// into it is `unsafe`; a safe abstraction over it never hands out a view
// of its contents.
//
// `Memo[K, V]` is that abstraction for caches filled on read paths: it
// returns values by copy, never a view into itself, takes no callbacks,
// and is not `Sync`. `K` hashes and compares the way the compiler
// generates it; `V` holds no references, raw pointers, `str` or slices.

use std.collections

pub type Interior[T] {
    value: T,
}

pub unsafe fn Interior.new[T](contents: T) -> Interior[T]: Interior { value: contents }

impl[T] Interior[T]:
    // The contents' address. Writes through it are visible to every view
    // of this `Interior`.
    pub unsafe fn ptr() -> *mut T: &raw const self.value as *mut T

pub type Memo[K, V] {
    cell: Interior[HashMap[K, V]],
}

pub fn Memo.new[K, V]() -> Memo[K, V]:
    Memo { cell: unsafe { Interior.new(HashMap.new()) } }

impl[K, V] Memo[K, V]:
    // The value cached for `key`, copied out.
    pub fn get(key: &K) -> Option[V]:
        let map = unsafe { self.cell.ptr() }
        // SEED-BOUND: the pinned seed, which compiles src/ and so this module,
        // does not copy an `Option[&V]` out at an owned `Option[V]` tail (D22);
        // the tail is `(unsafe *map).get(key)` once a seed carries that.
        match (unsafe *map).get(key):
            Some(v) => Some(*v)
            None => None

    pub fn contains(key: &K) -> bool:
        let map = unsafe { self.cell.ptr() }
        (unsafe *map).contains(key)

    // Cache `value` for `key`, replacing what was there.
    pub fn insert(key: K, value: V):
        let map = unsafe { self.cell.ptr() }
        (unsafe *map).insert(key, value)

    // Forget `key`, returning what was cached for it.
    pub fn remove(key: &K) -> Option[V]:
        let map = unsafe { self.cell.ptr() }
        (unsafe *map).remove(key)

    pub fn len() -> isize:
        let map = unsafe { self.cell.ptr() }
        (unsafe *map).len()

    pub fn clear():
        let map = unsafe { self.cell.ptr() }
        (unsafe *map).clear()
