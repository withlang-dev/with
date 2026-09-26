//! expect-stdout: 127
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
    print(f"{lc.unwrap().int_frac_digits as i32}")
