// N-body: five-body gravitational integration in f64, 50M steps.
// Timed region: the integration loop. Checksum: final system energy.
use std.time

const STEPS: i32 = 50000000
// Float constants are not comptime-evaluable yet (withlang-dev/with#1668).
fn solar_mass() -> f64: 4.0 * 3.141592653589793 * 3.141592653589793
fn days_per_year() -> f64: 365.24

type Body { x: f64, y: f64, z: f64, vx: f64, vy: f64, vz: f64, mass: f64 }
impl Copy for Body

type System { bodies: Vec[Body] }

fn solar_system() -> System:
    var bodies: Vec[Body] = Vec.with_capacity(5)
    bodies.push(Body { x: 0.0, y: 0.0, z: 0.0, vx: 0.0, vy: 0.0, vz: 0.0, mass: solar_mass() })
    bodies.push(Body {
        x: 4.84143144246472090e+00, y: -1.16032004402742839e+00, z: -1.03622044471123109e-01,
        vx: 1.66007664274403694e-03 * days_per_year(), vy: 7.69901118419740425e-03 * days_per_year(),
        vz: -6.90460016972063023e-05 * days_per_year(), mass: 9.54791938424326609e-04 * solar_mass(),
    })
    bodies.push(Body {
        x: 8.34336671824457987e+00, y: 4.12479856412430479e+00, z: -4.03523417114321381e-01,
        vx: -2.76742510726862411e-03 * days_per_year(), vy: 4.99852801234917238e-03 * days_per_year(),
        vz: 2.30417297573763929e-05 * days_per_year(), mass: 2.85885980666130812e-04 * solar_mass(),
    })
    bodies.push(Body {
        x: 1.28943695621391310e+01, y: -1.51111514016986312e+01, z: -2.23307578892655734e-01,
        vx: 2.96460137564761618e-03 * days_per_year(), vy: 2.37847173959480950e-03 * days_per_year(),
        vz: -2.96589568540237556e-05 * days_per_year(), mass: 4.36624404335156298e-05 * solar_mass(),
    })
    bodies.push(Body {
        x: 1.53796971148509165e+01, y: -2.59193146099879641e+01, z: 1.79258772950371181e-01,
        vx: 2.68067772490389322e-03 * days_per_year(), vy: 1.62824170038242295e-03 * days_per_year(),
        vz: -9.51592254519715870e-05 * days_per_year(), mass: 5.15138902046611451e-05 * solar_mass(),
    })
    System { bodies }

extend System:
    fn offset_momentum(mut self: Self):
        var px = 0.0
        var py = 0.0
        var pz = 0.0
        for i in 0..self.bodies.len():
            px = px + self.bodies[i].vx * self.bodies[i].mass
            py = py + self.bodies[i].vy * self.bodies[i].mass
            pz = pz + self.bodies[i].vz * self.bodies[i].mass
        self.bodies[0].vx = -px / solar_mass()
        self.bodies[0].vy = -py / solar_mass()
        self.bodies[0].vz = -pz / solar_mass()

    fn energy(self: &Self) -> f64:
        var e = 0.0
        let n = self.bodies.len()
        for i in 0..n:
            let b: Body = self.bodies[i]
            e = e + 0.5 * b.mass * (b.vx * b.vx + b.vy * b.vy + b.vz * b.vz)
            for j in (i + 1)..n:
                let o: Body = self.bodies[j]
                let dx = b.x - o.x
                let dy = b.y - o.y
                let dz = b.z - o.z
                e = e - b.mass * o.mass / sqrt(dx * dx + dy * dy + dz * dz)
        e

    fn advance(mut self: Self, dt: f64):
        let n = self.bodies.len()
        for i in 0..n:
            for j in (i + 1)..n:
                let dx = self.bodies[i].x - self.bodies[j].x
                let dy = self.bodies[i].y - self.bodies[j].y
                let dz = self.bodies[i].z - self.bodies[j].z
                let distance2 = dx * dx + dy * dy + dz * dz
                let mag = dt / (distance2 * sqrt(distance2))
                let mi = self.bodies[i].mass * mag
                let mj = self.bodies[j].mass * mag
                self.bodies[i].vx = self.bodies[i].vx - dx * mj
                self.bodies[i].vy = self.bodies[i].vy - dy * mj
                self.bodies[i].vz = self.bodies[i].vz - dz * mj
                self.bodies[j].vx = self.bodies[j].vx + dx * mi
                self.bodies[j].vy = self.bodies[j].vy + dy * mi
                self.bodies[j].vz = self.bodies[j].vz + dz * mi
        for i in 0..n:
            self.bodies[i].x = self.bodies[i].x + dt * self.bodies[i].vx
            self.bodies[i].y = self.bodies[i].y + dt * self.bodies[i].vy
            self.bodies[i].z = self.bodies[i].z + dt * self.bodies[i].vz

fn main:
    var system = solar_system()
    system.offset_momentum()
    let before = system.energy()
    let start = now_ns()
    for _ in 0..STEPS: system.advance(0.01)
    let elapsed_ms = (now_ns() - start) as f64 / 1000000.0
    let after = system.energy()
    print(f"energy_before {before:.9}")
    print(f"elapsed_ms {elapsed_ms:.3}")
    print(f"checksum {after:.9}")
