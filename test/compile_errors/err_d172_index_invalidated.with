//! expect-error: `pools[0]` is resolved before the arguments, and `pools.push_new()` may reallocate `pools`; bind the argument to a local first
// D172 (3), §3.2a: an index projection is resolved before the arguments,
// so an argument that mutates the indexed container is an error.
type Pool:
    n: i32

impl Pool:
    mut fn bump(v: i32): self.n = self.n + v

extend List[Pool]:
    mut fn push_new() -> i32:
        self.push(Pool { n: 0 })
        1

fn main:
    var pools = [Pool { n: 0 }]
    pools[0].bump(pools.push_new())
    print(pools.len())
