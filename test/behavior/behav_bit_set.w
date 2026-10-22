//! expect-stdout: ok

// BitSet over the STC cbits (docs/proposals/stdlib_sourcing_plan.md Phase
// 3): set, clear, flip and test, count, resize, and the set-bit traversal.

use std.collections.bit_set.BitSet

fn main:
    var bits = BitSet.new(130)
    assert(bits.len() == 130 and bits.count() == 0)
    bits.set(0)
    bits.set(64)
    bits.set(129)
    assert(bits.test(0) and bits.test(64) and bits.test(129) and not bits.test(1))
    assert(bits.count() == 3)
    bits.flip(1)
    bits.clear(64)
    assert(bits.test(1) and not bits.test(64) and bits.count() == 3)
    var cursor = bits.iter()
    var seen: List[isize] = []
    while true:
        match cursor.next():
            Some(i) => seen.push(i)
            None => break
    assert(seen == [0, 1, 129])
    bits.resize(200, true)
    assert(bits.len() == 200 and bits.count() == 3 + 70)
    bits.set_all(false)
    assert(bits.count() == 0)
    var full = BitSet.with_value(10, true)
    assert(full.count() == 10)
    print("ok")
