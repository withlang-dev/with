//! expect-error: an argument retains access to the `mut` receiver `pool` when the call begins (§3.2)
// D172 (3), §3.2a: an argument may mutate the receiver's place, but its
// result may not retain access to it; a view into the pool is still live
// when add_named begins.
type Pool:
    names: List[str]

impl Pool:
    mut fn add_named(name: &str): self.names.push(name)
    fn first() -> &str: self.names[0]

fn main:
    var pool = Pool { names: ["a"] }
    pool.add_named(pool.first())
    print(pool.names.len())
