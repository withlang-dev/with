// #3187: a generic method of another module binds a local named like a
// script's top-level binding; the local wins (D184), as it does in a
// non-generic function.
pub type Pair[T] { a: T, b: T }

impl[T] Pair[T]:
    pub fn first() -> &T:
        let i = 0
        if i == 0: &self.a else: &self.b
