//! expect-check-fail: cannot mutate `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `str` global, viewed by
// a local `let r = &G`, written directly
// while the view is live.
// A call writes every global its callee writes.

var G: str = "ab" ++ "cd"

fn main:
    let r = &G
    G = "wx" ++ "yz"
    print(r)
