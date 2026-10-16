//! expect-stdout: issued 7
//! expect-stdout: used 7
//! expect-stdout: released 7
//! expect-stdout: ok

// D120 (§4.3): `resource type` declares a struct a resource by its meaning;
// on a Drop type the keyword is allowed and redundant. A resource moves:
// handing the permit to `use_permit` is its last use, and the drop runs
// once, there.
resource type Permit { id: u64 }
impl Drop for Permit:
    move fn drop(): print(f"released {self.id}")

fn issue(id: u64) -> Permit:
    print(f"issued {id}")
    Permit { id: id }

fn use_permit(p: Permit): print(f"used {p.id}")

fn main:
    let resource = 7    // an identifier: the keyword is contextual
    let p = issue(resource)
    use_permit(p)
    print("ok")
