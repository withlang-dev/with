// std.collections.bit_set — BitSet: a dynamic bitset over the migrated STC
// `cbits` (docs/completed/stdlib_sourcing_plan.md, Phase 3; the facade map's
// primary engine). The simplest facade shape: an owning handle over engine
// storage, the `Regex` anatomy.
//
// Complexity contract: O(1) set, clear, flip and test; O(n/64) count.

use std.option
use std.engines.stc.defs
use std.engines.stc.facade_shapes

/// `len` bits, all clear unless built `with_value`; `set`/`clear`/`flip`
/// mutate, `test` observes; an out-of-range bit panics.
pub type BitSet { bits: cbits }

pub fn BitSet.new(len: isize) -> BitSet:
    BitSet { bits: cbits_with_size(len as c_long, false) }

pub fn BitSet.with_value(len: isize, value: bool) -> BitSet:
    BitSet { bits: cbits_with_size(len as c_long, value) }

impl BitSet:
    pub fn len() -> isize: self.bits.size() as isize
    fn check(i: isize): assert(i >= 0 and i < self.len(), "BitSet index out of bounds")

    pub fn test(i: isize) -> bool:
        self.check(i)
        self.bits.test(i as c_long)

    pub mut fn set(i: isize):
        self.check(i)
        self.bits.set(i as c_long)

    pub mut fn clear(i: isize):
        self.check(i)
        self.bits.reset(i as c_long)

    pub mut fn flip(i: isize):
        self.check(i)
        self.bits.flip(i as c_long)

    pub mut fn set_all(value: bool): unsafe { cbits_set_all(&raw mut self.bits, value) }

    /// Grows or shrinks to `len` bits; new bits take `value`.
    pub mut fn resize(len: isize, value: bool): assert(self.bits.resize(len as c_long, value))

    /// The number of set bits.
    pub fn count() -> isize: unsafe { cbits_count(&raw const self.bits) } as isize

    /// The indices of the set bits, ascending.
    pub fn iter() -> BitSetIter:
        BitSetIter { bits: (&raw const self.bits) as i64, index: 0, len: self.len() }

impl Drop for BitSet:
    move fn drop(): unsafe { cbits_drop(&raw mut self.bits) }

pub type BitSetIter ephemeral { bits: i64, index: isize, len: isize }

impl BitSetIter:
    pub mut fn next() -> Option[isize]:
        while self.index < self.len:
            let i = self.index
            self.index = i + 1
            if unsafe { (*(self.bits as *const cbits)).test(i as c_long) }: return Some(i)
        None
