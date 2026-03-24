// ecs_bench.w — ECS benchmark: SoA storage, bitset queries, 1M entities
use c_import("<time.h>")

type Position = { x: f32, y: f32 }
type Velocity = { x: f32, y: f32 }
type Health = { hp: f32, max_hp: f32 }
type Damage = { dps: f32 }

let HAS_POS: u8 = 1u8
let HAS_VEL: u8 = 2u8
let HAS_HP: u8 = 4u8
let HAS_DMG: u8 = 8u8
let MAX_ENTITIES = 1048576

type World = {
    mask: Vec[u8],
    pos: Vec[Position],
    vel: Vec[Velocity],
    hp: Vec[Health],
    dmg: Vec[Damage],
    count: i32,
}

fn World.new() -> World:
    World {
        mask: Vec.with_capacity(MAX_ENTITIES),
        pos: Vec.with_capacity(MAX_ENTITIES),
        vel: Vec.with_capacity(MAX_ENTITIES),
        hp: Vec.with_capacity(MAX_ENTITIES),
        dmg: Vec.with_capacity(MAX_ENTITIES),
        count: 0,
    }

fn World.spawn(self: &mut World) -> i32:
    let id = self.count
    self.mask.push(0u8)
    self.pos.push(Position { x: 0.0, y: 0.0 })
    self.vel.push(Velocity { x: 0.0, y: 0.0 })
    self.hp.push(Health { hp: 0.0, max_hp: 0.0 })
    self.dmg.push(Damage { dps: 0.0 })
    self.count = self.count + 1
    id

fn World.add_pos(self: &mut World, id: i32, p: Position):
    self.mask[id] = self.mask[id] | HAS_POS
    self.pos[id] = p

fn World.add_vel(self: &mut World, id: i32, v: Velocity):
    self.mask[id] = self.mask[id] | HAS_VEL
    self.vel[id] = v

fn World.add_health(self: &mut World, id: i32, h: Health):
    self.mask[id] = self.mask[id] | HAS_HP
    self.hp[id] = h

fn World.add_damage(self: &mut World, id: i32, d: Damage):
    self.mask[id] = self.mask[id] | HAS_DMG
    self.dmg[id] = d

fn World.system_movement(self: &mut World, dt: f32):
    let need = HAS_POS | HAS_VEL
    for i in 0..self.count:
        if self.mask[i] & need == need:
            self.pos[i].x = self.pos[i].x + self.vel[i].x * dt
            self.pos[i].y = self.pos[i].y + self.vel[i].y * dt

fn World.system_damage(self: &mut World, dt: f32):
    let need = HAS_HP | HAS_DMG
    for i in 0..self.count:
        if self.mask[i] & need == need:
            self.hp[i].hp = self.hp[i].hp - self.dmg[i].dps * dt

fn World.system_cleanup(self: &mut World):
    for i in 0..self.count:
        if self.mask[i] & HAS_HP != 0u8 and self.hp[i].hp <= 0.0f32:
            self.mask[i] = 0u8

fn World.count_alive(self: &World) -> i32:
    var n = 0
    for i in 0..self.count:
        if self.mask[i] != 0u8:
            n = n + 1
    n

extern fn with_eprintln(s: str) -> void
extern fn int_to_string(n: i32) -> str
extern fn i64_to_string(n: i64) -> str

fn main:
    var world = World.new()

    for i in 0..1000000:
        let id = world.spawn()
        let fi = i as f32

        if i % 10 < 7:
            world.add_pos(id, Position { x: fi * 0.1f32, y: fi * 0.2f32 })
            world.add_vel(id, Velocity {
                x: (fi % 100.0f32) * 0.01f32,
                y: ((fi + 50.0f32) % 100.0f32) * 0.01f32,
            })
        if i % 10 < 5:
            world.add_health(id, Health { hp: 100.0f32, max_hp: 100.0f32 })
        if i % 10 < 3:
            world.add_damage(id, Damage { dps: 0.5f32 + (fi % 10.0f32) * 0.1f32 })

    with_eprintln(f"Entities: {world.count}")
    with_eprintln(f"Alive: {world.count_alive()}")

    let start = clock()
    let dt: f32 = 1.0f32 / 60.0f32
    for _ in 0..1000:
        world.system_movement(dt)
        world.system_damage(dt)
        world.system_cleanup()

    let elapsed = clock() - start
    let cps: i64 = 1000000  // CLOCKS_PER_SEC on macOS
    let secs = elapsed / cps
    let msecs = ((elapsed % cps) * 1000i64) / cps
    with_eprintln(f"1000 ticks: {secs}.{msecs}s")
    with_eprintln(f"Alive after: {world.count_alive()}")

    var sum: f64 = 0.0
    for i in 0..world.count:
        if world.mask[i] & HAS_POS != 0u8:
            sum = sum + world.pos[i].x as f64
    with_eprintln(f"Checksum: {sum as i64}")
