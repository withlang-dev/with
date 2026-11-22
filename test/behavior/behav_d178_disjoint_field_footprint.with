//! expect-stdout: 3 2
//! expect-stdout: 10 8
//! expect-stdout: 5 1

// D178 (§3.6): within a package, a `mut fn` call mutates the field paths
// its body writes, at full depth. A view of a disjoint path survives the
// call: `names` views `self.labels` while `step` writes `physics.positions`
// and `n`; `first` views `self.physics.velocities` while `step` writes its
// sibling `positions`; a callee's footprint travels through the callee
// (`bump` calls `tick`, which writes `n`).
type Physics { positions: List[i32], velocities: List[i32] }
type World { physics: Physics, labels: List[str], n: i32 }

impl World:
    mut fn tick(): self.n += 1
    mut fn bump(): self.tick()
    mut fn step():
        self.physics.positions.push(self.n)
        self.tick()
    mut fn run() -> str:
        let names = self.labels
        self.step()
        self.step()
        f"{names.len()} {self.n}"
    mut fn speeds() -> str:
        let first = self.physics.velocities
        self.step()
        self.bump()
        f"{first[0]} {self.physics.positions.len()}"
    mut fn count() -> str:
        let tags = self.labels
        self.bump()
        f"{tags[0].len()} {self.n}"

fn main:
    var w = World { physics: Physics { positions: [1, 2, 3, 4, 5], velocities: [10] }, labels: ["alpha", "beta", "gamma"], n: 0 }
    print(w.run())
    print(w.speeds())
    var v = World { physics: Physics { positions: [], velocities: [] }, labels: ["alpha"], n: 0 }
    print(v.count())
