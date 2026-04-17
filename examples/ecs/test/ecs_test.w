// Tests for the ECS example


type Vec2 {
    x: f64,
    y: f64,
}

extend Vec2:
    fn new(x: f64, y: f64) -> Vec2: Vec2 { x, y }

    fn zero -> Vec2: Vec2 { x: 0.0, y: 0.0 }

    fn add(self: Vec2, other: Vec2) -> Vec2:
        Vec2 { x: self.x + other.x, y: self.y + other.y }

    fn scale(self: Vec2, s: f64) -> Vec2: Vec2 { x: self.x * s, y: self.y * s }

    fn length_sq(self: Vec2) -> f64: self.x * self.x + self.y * self.y

type Transform {
    x: f64,
    y: f64,
    rotation: f64,
    scale_val: f64,
}

type Velocity {
    vx: f64,
    vy: f64,
    angular: f64,
}

type Collider {
    radius: f64,
    layer: i32,
    mask: i32,
}

type Entity {
    id: i32,
    generation: i32,
}

fn make_entity(id: i32) -> Entity: Entity { id, generation: 1 }

fn make_transform(x: f64, y: f64) -> Transform:
    Transform { x, y, rotation: 0.0, scale_val: 1.0 }

fn make_velocity(vx: f64, vy: f64) -> Velocity: Velocity { vx, vy, angular: 0.0 }

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

fn max[T](a: T, b: T) -> T: if a > b then a else b

fn min[T](a: T, b: T) -> T: if a < b then a else b

fn clamp[T](val: T, lo: T, hi: T) -> T: min(max(val, lo), hi)

enum InputDir { Idle | Up | Down | Left | Right }

fn dir_to_velocity(dir: InputDir, speed: f64) -> Velocity:
    match dir:
        Idle => make_velocity(0.0, 0.0)
        Up => make_velocity(0.0, 0.0 - speed)
        Down => make_velocity(0.0, speed)
        Left => make_velocity(0.0 - speed, 0.0)
        Right => make_velocity(speed, 0.0)

@[test]
fn test_ecs_example:
    // Test Vec2 creation
    let v1 = Vec2.new(3.0, 4.0)
    assert(v1.x == 3.0)
    assert(v1.y == 4.0)

    let vz = Vec2.zero()
    assert(vz.x == 0.0)
    assert(vz.y == 0.0)

    // Test Vec2 add
    let v2 = Vec2.new(1.0, 2.0)
    let v3 = v1.add(v2)
    assert(v3.x == 4.0)
    assert(v3.y == 6.0)

    // Test Vec2 scale
    let v4 = v1.scale(2.0)
    assert(v4.x == 6.0)
    assert(v4.y == 8.0)

    // Test Vec2 length_sq
    let len_sq = v1.length_sq()
    assert(len_sq == 25.0)

    // Test Entity creation
    let e = make_entity(42)
    assert(e.id == 42)
    assert(e.generation == 1)

    // Test Transform and Velocity
    let t = make_transform(100.0, 200.0)
    assert(t.x == 100.0)
    assert(t.y == 200.0)
    assert(t.rotation == 0.0)
    assert(t.scale_val == 1.0)

    let v = make_velocity(10.0, 20.0)
    assert(v.vx == 10.0)
    assert(v.vy == 20.0)

    // Test apply_velocity
    let t2 = apply_velocity(t, v, 1.0)
    assert(t2.x == 110.0)
    assert(t2.y == 220.0)

    let t3 = apply_velocity(t, v, 0.5)
    assert(t3.x == 105.0)
    assert(t3.y == 210.0)

    // Test check_collision — overlapping
    let ta = make_transform(0.0, 0.0)
    let tb = make_transform(10.0, 0.0)
    let ca = Collider { radius: 8.0, layer: 1, mask: 1 }
    let cb = Collider { radius: 8.0, layer: 1, mask: 1 }
    assert(check_collision(ta, ca, tb, cb))

    // Test check_collision — not overlapping
    let tc = make_transform(100.0, 0.0)
    assert(not check_collision(ta, ca, tc, cb))

    // Test generic clamp
    assert(clamp(5, 0, 10) == 5)
    assert(clamp(-5, 0, 10) == 0)
    assert(clamp(15, 0, 10) == 10)

    // Test float clamp
    assert(clamp(5.0, 0.0, 10.0) == 5.0)
    assert(clamp(-1.0, 0.0, 10.0) == 0.0)
    assert(clamp(99.0, 0.0, 10.0) == 10.0)

    // Test generic max/min
    assert(max(3, 7) == 7)
    assert(min(3, 7) == 3)
    assert(max(3.0, 7.0) == 7.0)
    assert(min(3.0, 7.0) == 3.0)

    // Test dir_to_velocity
    let dv_none = dir_to_velocity(.Idle, 100.0)
    assert(dv_none.vx == 0.0)
    assert(dv_none.vy == 0.0)

    let dv_right = dir_to_velocity(.Right, 100.0)
    assert(dv_right.vx == 100.0)
    assert(dv_right.vy == 0.0)

    let dv_up = dir_to_velocity(.Up, 50.0)
    assert(dv_up.vx == 0.0)
    assert(dv_up.vy == -50.0)

    let dv_down = dir_to_velocity(.Down, 50.0)
    assert(dv_down.vx == 0.0)
    assert(dv_down.vy == 50.0)

    let dv_left = dir_to_velocity(.Left, 75.0)
    assert(dv_left.vx == -75.0)
    assert(dv_left.vy == 0.0)
