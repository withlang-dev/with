//! expect-debug-alloc: leak count=0
//! expect-stdout: before
//! expect-stdout: after
// §29.6 (D95, #2074): `let _ = x` drops `x` at that statement, once.
type Noisy { name: str }

impl Drop for Noisy:
    move fn drop(): print(self.name)

fn main:
    let n = Noisy { name: "before".to_lower() }
    let _ = n
    print("after")
