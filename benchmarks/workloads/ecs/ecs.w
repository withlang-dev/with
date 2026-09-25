// ECS update: structure-of-arrays storage, bitmask queries, 1M entities.
// Timed region: 1000 ticks of movement, damage, and cleanup systems.
use std.time

const ENTITIES: i32 = 1000000
const TICKS: i32 = 1000
const HAS_POS: u8 = 1
const HAS_VEL: u8 = 2
const HAS_HP: u8 = 4
const HAS_DMG: u8 = 8

type Position { x: f32 = 0.0, y: f32 = 0.0 }
type Velocity { x: f32 = 0.0, y: f32 = 0.0 }
type Health { hp: f32 = 0.0 }
type Damage { dps: f32 = 0.0 }
impl Copy for Position
impl Copy for Velocity
impl Copy for Health
impl Copy for Damage

fn filled[T](value: T, count: i32) -> Vec[T]:
    var slots: Vec[T] = Vec.with_capacity(count)
    for _ in 0..count: slots.push(value)
    slots

type World {
    mask: Vec[u8],
    pos: Vec[Position],
    vel: Vec[Velocity],
    hp: Vec[Health],
    dmg: Vec[Damage],
    count: i32 = 0,
}

fn World.new() -> World:
    World {
        mask: filled(0 as u8, ENTITIES),
        pos: filled(Position {}, ENTITIES),
        vel: filled(Velocity {}, ENTITIES),
        hp: filled(Health {}, ENTITIES),
        dmg: filled(Damage {}, ENTITIES),
    }

extend World:
    fn create(mut self: Self) -> i32:
        let id = self.count
        self.count += 1
        id

    fn add_pos(mut self: Self, id: i32, p: Position):
        self.mask[id] = self.mask[id] | HAS_POS
        self.pos[id] = p

    fn add_vel(mut self: Self, id: i32, v: Velocity):
        self.mask[id] = self.mask[id] | HAS_VEL
        self.vel[id] = v

    fn add_health(mut self: Self, id: i32, h: Health):
        self.mask[id] = self.mask[id] | HAS_HP
        self.hp[id] = h

    fn add_damage(mut self: Self, id: i32, d: Damage):
        self.mask[id] = self.mask[id] | HAS_DMG
        self.dmg[id] = d

    fn system_movement(mut self: Self, dt: f32):
        let need = HAS_POS | HAS_VEL
        for i in 0..self.count:
            if (self.mask[i] & need) == need:
                self.pos[i].x = self.pos[i].x + self.vel[i].x * dt
                self.pos[i].y = self.pos[i].y + self.vel[i].y * dt

    fn system_damage(mut self: Self, dt: f32):
        let need = HAS_HP | HAS_DMG
        for i in 0..self.count:
            if (self.mask[i] & need) == need:
                self.hp[i].hp = self.hp[i].hp - self.dmg[i].dps * dt

    fn system_cleanup(mut self: Self):
        for i in 0..self.count:
            if (self.mask[i] & HAS_HP) != 0 and self.hp[i].hp <= 0.0:
                self.mask[i] = 0

    fn count_alive(self: &Self) -> i32:
        var n = 0
        for i in 0..self.count:
            if self.mask[i] != 0: n += 1
        n

fn main:
    var world = World.new()
    // 70% move, 50% have health, 30% take damage.
    for i in 0..ENTITIES:
        let id = world.create()
        let fi = i as f32
        if i % 10 < 7:
            world.add_pos(id, Position { x: fi * 0.1, y: fi * 0.2 })
            world.add_vel(id, Velocity { x: (fi % 100.0) * 0.01, y: ((fi + 50.0) % 100.0) * 0.01 })
        if i % 10 < 5: world.add_health(id, Health { hp: 100.0 })
        if i % 10 < 3: world.add_damage(id, Damage { dps: 0.5 + (fi % 10.0) * 0.1 })
    let alive_before = world.count_alive()

    let start = now_ns()
    let dt: f32 = 1.0 / 60.0
    for _ in 0..TICKS:
        world.system_movement(dt)
        world.system_damage(dt)
        world.system_cleanup()
    let elapsed_ms = (now_ns() - start) as f64 / 1000000.0

    var sum: f64 = 0.0
    for i in 0..world.count:
        if (world.mask[i] & HAS_POS) != 0: sum = sum + world.pos[i].x as f64
    print(f"entities {world.count} alive_before {alive_before} alive_after {world.count_alive()}")
    print(f"elapsed_ms {elapsed_ms:.3}")
    print(f"checksum {sum:.2}")
