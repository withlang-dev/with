//! expect-stdout: 4

// §4.9a (D103): a value converts to Option[T] where one is demanded — the field site.
type Holder { slot: Option[i32] }
fn main:
    let h = Holder { slot: 4 }
    print(f"{h.slot ?? 0}")
