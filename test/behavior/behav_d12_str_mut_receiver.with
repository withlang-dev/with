//! expect-stdout: ok

// D12/#678 (§9.5): `mut fn` on a str owner reassigns the CALLER's slice —
// share-place over the {ptr,len} fat pointer, the callee writes both
// fields. Mode decides, not the owner's type: str is Copy, yet `mut fn`
// borrows the caller's place; by-value str params still copy.

extend str:
    mut fn shout(): self = self ++ "!"
    mut fn behead(): self = self.slice(1, self.len())
    mut fn clear_if(go: bool):
        if not go:
            return
        self = ""

fn shout_a_copy(s: str) -> str:
    var t = s
    t.shout()
    t

fn main:
    // Reassignment reaches the caller: concat (new buffer) and sub-slice
    // (view into the same buffer) both land in the caller's binding.
    var s = "hello"
    s.shout()
    assert(s == "hello!")
    s.behead()
    assert(s == "ello!")

    // Both fields of the fat pointer travel: len changes are visible.
    assert(s.len() == 5)

    // By-value param: the callee owns an explicit clone (D28: str moves),
    // the caller is untouched.
    assert(shout_a_copy(s) == "ello!!")
    assert(s == "ello!")

    // Branch and loop shapes drive the caller's place.
    s.clear_if(false)
    assert(s == "ello!")
    s.clear_if(true)
    assert(s == "")
    var t = "xxxx"
    var n = 0
    while t.len() > 1:
        t.behead()
        n = n + 1
    assert(t == "x" and n == 3)

    print("ok")
