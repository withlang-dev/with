//! expect-error: type 'Permit' cannot implement Copy: it is declared 'resource type', a value never duplicated (§4.3)

// D120 (§4.3): `resource type` declares a struct whose meaning forbids
// duplication (a permit, an ID allocator, a one-shot token): value fields,
// but copying one is a bug, so it cannot be Copy.
resource type Permit { id: u64 }
impl Copy for Permit
fn main:
    let p = Permit { id: 1 }
    print(p.id)
