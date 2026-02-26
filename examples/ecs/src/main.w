// ===================================================================
// ECS (Entity-Component-System) Demo — Simplified
//
// Demonstrates:
//   - Structs as components
//   - Extend blocks for methods
//   - Generics (generic functions)
//   - Enums with pattern matching
//   - For loops, arrays, pipeline
//   - String interpolation
//   - Float arithmetic and casting
// ===================================================================

// --- Math ---

type Vec2 = {
    x: f64,
    y: f64,
}

extend Vec2 =
    fn new(x: f64, y: f64) -> Vec2:
        Vec2 { x: x, y: y }

    fn zero -> Vec2:
        Vec2 { x: 0.0, y: 0.0 }

    fn add(self: Vec2, other: Vec2) -> Vec2:
        Vec2 { x: self.x + other.x, y: self.y + other.y }

    fn scale(self: Vec2, s: f64) -> Vec2:
        Vec2 { x: self.x * s, y: self.y * s }

    fn length_sq(self: Vec2) -> f64:
        self.x * self.x + self.y * self.y

// --- Components ---

type Transform = {
    x: f64,
    y: f64,
    rotation: f64,
    scale_val: f64,
}

type Velocity = {
    vx: f64,
    vy: f64,
    angular: f64,
}

type Sprite = {
    texture_id: i32,
    width: i32,
    height: i32,
    layer: i32,
    visible: bool,
}

type Collider = {
    radius: f64,
    layer: i32,
    mask: i32,
}

// --- Entity Handle ---

type Entity = {
    id: i32,
    generation: i32,
}

// --- World (simplified: fixed-size arrays) ---

fn make_entity(id: i32) -> Entity:
    Entity { id: id, generation: 1 }

fn make_transform(x: f64, y: f64) -> Transform:
    Transform { x: x, y: y, rotation: 0.0, scale_val: 1.0 }

fn make_velocity(vx: f64, vy: f64) -> Velocity:
    Velocity { vx: vx, vy: vy, angular: 0.0 }

// --- Systems ---

fn apply_velocity(t: Transform, v: Velocity, dt: f64) -> Transform:
    Transform {
        x: t.x + v.vx * dt,
        y: t.y + v.vy * dt,
        rotation: t.rotation + v.angular * dt,
        scale_val: t.scale_val,
    }

fn check_collision(t1: Transform, c1: Collider, t2: Transform, c2: Collider) -> bool:
    let dx = t1.x - t2.x
    let dy = t1.y - t2.y
    let dist_sq = dx * dx + dy * dy
    let r_sum = c1.radius + c2.radius
    dist_sq < r_sum * r_sum

// --- Generic utility ---

fn max[T](a: T, b: T) -> T:
    if a > b then a else b

fn min[T](a: T, b: T) -> T:
    if a < b then a else b

fn clamp[T](val: T, lo: T, hi: T) -> T:
    min(max(val, lo), hi)

// --- Input ---

type InputDir = None | Up | Down | Left | Right

fn dir_to_velocity(dir: InputDir, speed: f64) -> Velocity:
    match dir
        None -> make_velocity(0.0, 0.0)
        Up -> make_velocity(0.0, 0.0 - speed)
        Down -> make_velocity(0.0, speed)
        Left -> make_velocity(0.0 - speed, 0.0)
        Right -> make_velocity(speed, 0.0)

// --- Main ---

fn main -> i32:
    println("=== ECS Demo ===")

    // Create entities
    let player = make_entity(0)
    let enemy1 = make_entity(1)
    let enemy2 = make_entity(2)
    println("Spawned 3 entities (player + 2 enemies)")

    // Initialize transforms
    var player_t = make_transform(100.0, 300.0)
    var enemy1_t = make_transform(200.0, 300.0)
    var enemy2_t = make_transform(400.0, 300.0)

    // Initialize velocities
    var player_v = make_velocity(0.0, 0.0)
    let enemy1_v = make_velocity(0.0, 30.0)
    let enemy2_v = make_velocity(0.0, 50.0)

    // Colliders
    let player_c = Collider { radius: 16.0, layer: 1, mask: 0xFF }
    let enemy_c = Collider { radius: 16.0, layer: 2, mask: 0x01 }

    let dt = 1.0 / 60.0

    // Simulate 5 frames
    println("--- Simulating 5 frames ---")

    // Frame 0: player moves right
    player_v = dir_to_velocity(Right, 100.0)
    player_t = apply_velocity(player_t, player_v, dt)
    enemy1_t = apply_velocity(enemy1_t, enemy1_v, dt)
    enemy2_t = apply_velocity(enemy2_t, enemy2_v, dt)
    println("Frame 0: player=({player_t.x:.1}, {player_t.y:.1})")

    // Frame 1: continue
    player_t = apply_velocity(player_t, player_v, dt)
    enemy1_t = apply_velocity(enemy1_t, enemy1_v, dt)
    enemy2_t = apply_velocity(enemy2_t, enemy2_v, dt)
    println("Frame 1: player=({player_t.x:.1}, {player_t.y:.1})")

    // Frame 2: player moves up-right
    player_v = make_velocity(100.0, -100.0)
    player_t = apply_velocity(player_t, player_v, dt)
    enemy1_t = apply_velocity(enemy1_t, enemy1_v, dt)
    println("Frame 2: player=({player_t.x:.1}, {player_t.y:.1})")

    // Check collision
    let collision = check_collision(player_t, player_c, enemy1_t, enemy_c)
    if collision then println("Collision detected!") else println("No collision")

    // Generic clamp demo
    let clamped = clamp(player_t.x, 0.0, 800.0)
    println("Clamped x: {clamped:.1}")

    // Vec2 operations
    let v1 = Vec2.new(3.0, 4.0)
    let v2 = Vec2.new(1.0, 2.0)
    let v3 = v1.add(v2)
    println("Vec2 add: ({v3.x:.1}, {v3.y:.1})")

    let v4 = v1.scale(2.0)
    println("Vec2 scale: ({v4.x:.1}, {v4.y:.1})")

    let len_sq = v1.length_sq()
    println("Vec2 length_sq: {len_sq:.1}")

    println("=== Demo complete ===")
