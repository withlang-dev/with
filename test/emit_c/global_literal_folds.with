//! expect-debug-alloc: leak count=0
//! expect-stdout: 3 127 31
//! expect-stdout: 3

// #2219: a global built from another constant's literal — its `.len()`, an
// element, a field — is initialized data in both backends. Lowered at
// startup instead, the emitted C program allocated the referenced List at
// init and never released it (pcre2's `_pcre2_utt_size_8 = _pcre2_utt_8.len()`
// leaked two blocks in every emit-C fixture).
type Range { lo: i32, hi: i32 }
type Group { count: u64, first_hi: i32, last_lo: i32 }

let RANGES: List[Range] = [Range { lo: 0, hi: 31 }, Range { lo: 127, hi: 159 }, Range { lo: 31, hi: 40 }]
let GROUP: Group = Group { count: (RANGES.len() as u64), first_hi: RANGES[0].hi, last_lo: RANGES[1].lo }
let RANGE_COUNT: i32 = ((RANGES.len() as u64) as i32)

fn main:
    print(f"{GROUP.count} {GROUP.last_lo} {GROUP.first_hi}")
    print(f"{RANGE_COUNT}")
