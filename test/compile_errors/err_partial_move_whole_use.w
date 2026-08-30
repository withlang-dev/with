//! expect-check-fail: a field never moves out implicitly

// #782 → D32 (§2.2): the assignment-RHS bare field read that used to move
// implicitly (and made the later whole use an error) now errors at the
// move site itself — the site-local rule subsumes the flow-conditional one.

type Capability { root: str, name: str }

fn takes_whole(c: &Capability) -> i64: c.root.len()

fn main:
    let cap = Capability { root: "/proj" ++ "", name: "ws" ++ "" }
    var picked = "" ++ ""
    picked = cap.root
    let n = takes_whole(cap)
    print_i64(n)
    print(picked)
