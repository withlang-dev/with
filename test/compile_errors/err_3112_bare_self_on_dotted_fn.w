//! expect-check-fail: a function outside a type has no receiver (§9.5), so this `self` needs its type: write `self: &Self`, or declare the method inside `impl Type:` as `fn name(…)`
// #3112: a written `self` with no type on a top-level `fn Type.name` names
// nothing (§9.5: such a function is associated, with no receiver). It was
// "method receiver mode is missing; compiler effects require `fn`"; it is refused at the receiver with the
// accepted spellings.
type Owned { n: i32 }

fn Owned.get(self) -> i32: self.n

fn main:
    var o = Owned { n: 0 }
    print(f"{o.get()}")
