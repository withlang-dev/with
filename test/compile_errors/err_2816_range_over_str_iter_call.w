//! expect-check-fail: cannot iterate over `Range[str]`: `str` has no successor (§4.7: a range iterates `T: One + Ord`)
// #2816, the explicit spelling: `.iter()` on a range of str is the same
// refusal as the `for`.
fn main:
    for c in ("a".."z").iter(): print(c)
