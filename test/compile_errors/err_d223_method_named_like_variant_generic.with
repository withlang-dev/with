//! expect-check-fail: `Nothing` is a variant of `Maybe` and cannot also be a method of it: `Maybe.Nothing` would name either (§9.3a)

// D223 (§9.3a): the rule holds for a generic enum, and is said once however
// many instances check the method.
enum Maybe[T]:
    Just(v: T)
    Nothing
impl[T] Maybe[T]:
    fn Nothing() -> i32: 1
fn main:
    let m: Maybe[i32] = Maybe.Nothing
    let k: Maybe[str] = Maybe.Nothing
    print(m.Nothing())
    print(k.Nothing())
