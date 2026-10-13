use common

const N: i64 = 100000 // BENCH_N
type P { x: f32, y: f32, z: f32, vx: f32, vy: f32, vz: f32 }
type Simulation { particles: Vec[P] }

impl Simulation:
    mut fn step():
        for i in 0..self.particles.len():
            self.particles[i].vy -= 0.0625
            self.particles[i].x += self.particles[i].vx
            self.particles[i].y += self.particles[i].vy
            self.particles[i].z += self.particles[i].vz
            if self.particles[i].y < 0.0:
                self.particles[i].y = 0.0 - self.particles[i].y
                self.particles[i].vy = 0.0 - self.particles[i].vy * 0.5

fn main:
    var sim = Simulation { particles: Vec.new() }
    var r: u64 = 12345
    for _ in 0..N:
        r = xs_next(r)
        sim.particles.push(P { x: xs_mod(r, 1024) as f32, y: xs_mod(r >> 12, 1024) as f32, z: xs_mod(r >> 24, 1024) as f32, vx: ((xs_mod(r >> 36, 256) - 128) as f32) / 16.0, vy: ((xs_mod(r >> 44, 256) - 128) as f32) / 16.0, vz: ((xs_mod(r >> 52, 256) - 128) as f32) / 16.0 })
    for _ in 0..200: sim.step()
    var total: i64 = 0
    for p in sim.particles:
        total += ((p.x * 16.0) as i64) + ((p.y * 16.0) as i64) + ((p.z * 16.0) as i64)
    print(sim.particles.len())
    print(total)
