//! expect-stdout: CHAR_MAX
//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows

// #1655 / §16.2b.7: a domain-touching call on a branch that RETURNS does
// not invalidate the view on the fall-through path — invalidation is
// path-sensitive like every other view-liveness rule. The shape every
// application writes: probe, bail out (cleaning up) on failure, read on
// success.
use c_import("c_facade_record.h")

c facade records:
    domain locale process
    fn localeconv
        returns borrow lconv from domain locale

fn main:
    let lc = localeconv()
    if lc.is_none():
        let _ = localeconv()
        return 1
    // In the "C" locale int_frac_digits is CHAR_MAX, the target's (255 where
    // char is unsigned, linux-aarch64): print the fact, not the number.
    let char_max = if (255 as c_char) as i32 == 255: 255 else: 127
    let digits = lc.unwrap().int_frac_digits as i32
    print(if digits == char_max: "CHAR_MAX" else: f"{digits}")
