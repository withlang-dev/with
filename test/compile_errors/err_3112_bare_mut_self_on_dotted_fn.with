//! expect-check-fail: a function outside a type has no receiver (§9.5), so this `self` needs its type: write `mut self: Self`, or declare the method inside `impl Type:` as `mut fn name(…)`
// #3112: a written `self` with no type on a top-level `fn Type.name` names
// nothing (§9.5: such a function is associated, with no receiver). It was
// an ICE in the MIR validator on a field write; it is refused at the receiver with the
// accepted spellings.
type Owned { n: i32 }

fn Owned.set(mut self, v: i32):
    self.n = v

fn main:
    var o = Owned { n: 0 }
    o.set(3)
