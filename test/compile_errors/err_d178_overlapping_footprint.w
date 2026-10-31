//! expect-check-fail: cannot mutate `self` while `first` is a live view into it

// D178 (§3.6): a `mut fn` whose footprint reaches the viewed path — here
// `physics` (a prefix of `physics.velocities`, assigned whole) — still
// conflicts with the live view.
type Physics { positions: List[i32], velocities: List[i32] }
type World { physics: Physics, n: i32 }

impl World:
    mut fn reset(): self.physics = Physics { positions: [], velocities: [] }
    mut fn speeds() -> i32:
        let first = self.physics.velocities
        self.reset()
        first[0]

fn main:
    var w = World { physics: Physics { positions: [], velocities: [10] }, n: 0 }
    print(f"{w.speeds()}")
