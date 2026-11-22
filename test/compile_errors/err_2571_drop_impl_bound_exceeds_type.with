//! expect-error: a `Drop` impl's bounds are the type's own

// #2571 (§2.4): a destructor runs for every instantiation, so a `Drop`
// impl cannot demand a bound the type does not.
type Holder[T] { v: T }
impl[T: Clone] Drop for Holder[T]:
    move fn drop(): print("dropped")
fn main:
    let h = Holder { v: 1 }
