//! expect-error: `pools[0]` is resolved before the arguments, and `grow(pools)` may reallocate `pools`; bind the argument to a local first
// D172 (3), §3.2a: the mutation may come through a call: `grow` takes
// `pools` as a `mut` parameter, which mutates it as surely as a method.
type Pool:
    n: i32

impl Pool:
    mut fn bump(v: i32): self.n = self.n + v

fn grow(mut pools: List[Pool]) -> i32:
    pools.push(Pool { n: 0 })
    1

fn main:
    var pools = [Pool { n: 0 }]
    pools[0].bump(grow(pools))
    print(pools.len())
