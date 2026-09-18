// T22/T15 probe: pure i31 helpers — word_count + ninv31.
// Oracle: python3 pow()/bit math (independent): ninv31(7)=1227133513,
// x*ninv & 0x7FFFFFFF == 0x7FFFFFFF for odd x.
use std.crypto.bigint
use std.builtins.print
use std.builtins.assert

fn main:
    assert(i31_word_count(0u32) == 0, "wc(0)")
    assert(i31_word_count(1u32) == 1, "wc(1)")
    assert(i31_word_count(31u32) == 1, "wc(31)")
    assert(i31_word_count(32u32) == 2, "wc(32)")
    assert(i31_word_count(62u32) == 2, "wc(62)")
    assert(i31_word_count(63u32) == 3, "wc(63)")
    let n7 = i31_ninv31(7u32)
    assert(n7 == 1227133513u32, "ninv31(7)")
    assert((7u32 *% n7 & 0x7FFFFFFFu32) == 0x7FFFFFFFu32, "ninv31(7) verify")
    let n13 = i31_ninv31(13u32)
    assert((13u32 *% n13 & 0x7FFFFFFFu32) == 0x7FFFFFFFu32, "ninv31(13) verify")
    let n997 = i31_ninv31(997u32)
    assert((997u32 *% n997 & 0x7FFFFFFFu32) == 0x7FFFFFFFu32, "ninv31(997) verify")
    print("bigint-pure-ok")
