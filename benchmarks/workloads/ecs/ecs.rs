// ECS update: structure-of-arrays storage, bitmask queries, 1M entities.
// Timed region: 1000 ticks of movement, damage, and cleanup systems.
const ENTITIES: usize = 1_000_000;
const TICKS: usize = 1000;
const HAS_POS: u8 = 1;
const HAS_VEL: u8 = 2;
const HAS_HP: u8 = 4;
const HAS_DMG: u8 = 8;

#[derive(Clone, Copy, Default)]
struct Position { x: f32, y: f32 }
#[derive(Clone, Copy, Default)]
struct Velocity { x: f32, y: f32 }
#[derive(Clone, Copy, Default)]
struct Health { hp: f32 }
#[derive(Clone, Copy, Default)]
struct Damage { dps: f32 }

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
            mask: vec![0u8; ENTITIES],
            pos: vec![Position::default(); ENTITIES],
            vel: vec![Velocity::default(); ENTITIES],
            hp: vec![Health::default(); ENTITIES],
            dmg: vec![Damage::default(); ENTITIES],
            count: 0,
        }
    }

    fn create(&mut self) -> usize {
        let id = self.count;
        self.count += 1;
        id
    }

    fn add_pos(&mut self, id: usize, p: Position) { self.mask[id] |= HAS_POS; self.pos[id] = p; }
    fn add_vel(&mut self, id: usize, v: Velocity) { self.mask[id] |= HAS_VEL; self.vel[id] = v; }
    fn add_health(&mut self, id: usize, h: Health) { self.mask[id] |= HAS_HP; self.hp[id] = h; }
    fn add_damage(&mut self, id: usize, d: Damage) { self.mask[id] |= HAS_DMG; self.dmg[id] = d; }

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
        self.mask[..self.count].iter().filter(|&&m| m != 0).count()
    }
}

fn main() {
    let mut world = World::new();
    // 70% move, 50% have health, 30% take damage.
    for i in 0..ENTITIES as u32 {
        let id = world.create();
        let fi = i as f32;
        if i % 10 < 7 {
            world.add_pos(id, Position { x: fi * 0.1, y: fi * 0.2 });
            world.add_vel(id, Velocity { x: (fi % 100.0) * 0.01, y: ((fi + 50.0) % 100.0) * 0.01 });
        }
        if i % 10 < 5 { world.add_health(id, Health { hp: 100.0 }); }
        if i % 10 < 3 { world.add_damage(id, Damage { dps: 0.5 + (fi % 10.0) * 0.1 }); }
    }
    let alive_before = world.count_alive();

    let start = std::time::Instant::now();
    let dt: f32 = 1.0 / 60.0;
    for _ in 0..TICKS {
        world.system_movement(dt);
        world.system_damage(dt);
        world.system_cleanup();
    }
    let elapsed_ms = start.elapsed().as_secs_f64() * 1000.0;

    let mut sum: f64 = 0.0;
    for i in 0..world.count {
        if world.mask[i] & HAS_POS != 0 { sum += world.pos[i].x as f64; }
    }
    println!("entities {} alive_before {} alive_after {}", world.count, alive_before, world.count_alive());
    println!("elapsed_ms {:.3}", elapsed_ms);
    println!("checksum {:.2}", sum);
}
