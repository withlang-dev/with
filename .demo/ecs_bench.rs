// ecs_bench.rs — ECS benchmark: SoA storage, bitset queries, 1M entities
// No external crates. Idiomatic Rust.

const MAX_ENTITIES: usize = 1_048_576;

#[derive(Clone, Copy, Default)]
struct Position { x: f32, y: f32 }

#[derive(Clone, Copy, Default)]
struct Velocity { x: f32, y: f32 }

#[derive(Clone, Copy, Default)]
struct Health { hp: f32, max_hp: f32 }

#[derive(Clone, Copy, Default)]
struct Damage { dps: f32 }

const HAS_POS: u8 = 1;
const HAS_VEL: u8 = 2;
const HAS_HP: u8 = 4;
const HAS_DMG: u8 = 8;

struct World {
    mask: Vec<u8>,
    pos: Vec<Position>,
    vel: Vec<Velocity>,
    hp: Vec<Health>,
    dmg: Vec<Damage>,
    count: usize,
}

impl World {
    fn new() -> Self {
        World {
            mask: vec![0u8; MAX_ENTITIES],
            pos: vec![Position::default(); MAX_ENTITIES],
            vel: vec![Velocity::default(); MAX_ENTITIES],
            hp: vec![Health::default(); MAX_ENTITIES],
            dmg: vec![Damage::default(); MAX_ENTITIES],
            count: 0,
        }
    }

    fn spawn(&mut self) -> usize {
        let id = self.count;
        self.count += 1;
        id
    }

    fn add_pos(&mut self, id: usize, p: Position) {
        self.mask[id] |= HAS_POS;
        self.pos[id] = p;
    }

    fn add_vel(&mut self, id: usize, v: Velocity) {
        self.mask[id] |= HAS_VEL;
        self.vel[id] = v;
    }

    fn add_health(&mut self, id: usize, h: Health) {
        self.mask[id] |= HAS_HP;
        self.hp[id] = h;
    }

    fn add_damage(&mut self, id: usize, d: Damage) {
        self.mask[id] |= HAS_DMG;
        self.dmg[id] = d;
    }

    fn system_movement(&mut self, dt: f32) {
        let need = HAS_POS | HAS_VEL;
        for i in 0..self.count {
            if self.mask[i] & need == need {
                self.pos[i].x += self.vel[i].x * dt;
                self.pos[i].y += self.vel[i].y * dt;
            }
        }
    }

    fn system_damage(&mut self, dt: f32) {
        let need = HAS_HP | HAS_DMG;
        for i in 0..self.count {
            if self.mask[i] & need == need {
                self.hp[i].hp -= self.dmg[i].dps * dt;
            }
        }
    }

    fn system_cleanup(&mut self) {
        for i in 0..self.count {
            if self.mask[i] & HAS_HP != 0 && self.hp[i].hp <= 0.0 {
                self.mask[i] = 0;
            }
        }
    }

    fn count_alive(&self) -> usize {
        let mut n = 0;
        for i in 0..self.count {
            if self.mask[i] != 0 {
                n += 1;
            }
        }
        n
    }
}

fn main() {
    let mut world = World::new();

    // Spawn 1M entities: 70% have pos+vel, 50% have health, 30% have damage
    for i in 0..1_000_000u32 {
        let id = world.spawn();
        let fi = i as f32;

        if i % 10 < 7 {
            world.add_pos(id, Position { x: fi * 0.1, y: fi * 0.2 });
            world.add_vel(id, Velocity { x: (fi % 100.0) * 0.01, y: ((fi + 50.0) % 100.0) * 0.01 });
        }
        if i % 10 < 5 {
            world.add_health(id, Health { hp: 100.0, max_hp: 100.0 });
        }
        if i % 10 < 3 {
            world.add_damage(id, Damage { dps: 0.5 + (fi % 10.0) * 0.1 });
        }
    }

    println!("Entities: {}", world.count);
    println!("Alive: {}", world.count_alive());

    let start = std::time::Instant::now();

    let dt = 1.0 / 60.0;
    for _ in 0..1000 {
        world.system_movement(dt);
        world.system_damage(dt);
        world.system_cleanup();
    }

    let elapsed = start.elapsed();
    println!("1000 ticks: {:.3}s", elapsed.as_secs_f64());
    println!("Alive after: {}", world.count_alive());

    // Checksum to prevent dead code elimination
    let mut sum: f64 = 0.0;
    for i in 0..world.count {
        if world.mask[i] & HAS_POS != 0 {
            sum += world.pos[i].x as f64;
        }
    }
    println!("Checksum: {:.2}", sum);
}
