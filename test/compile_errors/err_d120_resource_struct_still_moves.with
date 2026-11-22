//! expect-error: use of moved value

// D120 (§2.3, §4.3): a struct of value fields is a value and copies —
// unless it is declared a resource, whose identity its fields don't show
// (a permit, a token): a resource moves, and the moved binding is gone.
resource type Permit { id: i32 }

fn take(p: Permit) -> i32: p.id

fn main:
    let p = Permit { id: 1 }
    let a = take(p)
    let b = take(p)
    print(f"{a + b}")
