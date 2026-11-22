//! expect-check-fail: a function outside a type has no receiver (§9.5), so this `self` needs its type: write `move self: Self`, or declare the method inside `impl Type:` as `move fn name(…)`
// #3112: a written `self` with no type on a top-level `fn Type.name` names
// nothing (§9.5: such a function is associated, with no receiver). It was
// a code generation failure ("cannot lower FnAbi parameter"); it is refused at the receiver with the
// accepted spellings.
type Owned { n: i32 }

fn Owned.take(move self) -> i32: self.n

fn main:
    var o = Owned { n: 0 }
    print(f"{o.take()}")
