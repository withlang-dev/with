// Test: with blocks combined with record update and impl methods
type Config = {
    width: i32 = 800,
    height: i32 = 600,
    depth: i32 = 32,
    fullscreen: bool = false
}

impl Config =
    fn pixel_count(self: Config) -> i32 =
        self.width * self.height

    fn is_hd(self: Config) -> bool =
        self.width >= 1920 and self.height >= 1080

type Vec3 = {
    x: i32,
    y: i32,
    z: i32
}

impl Vec3 =
    fn length_sq(self: Vec3) -> i32 =
        self.x * self.x + self.y * self.y + self.z * self.z

    fn add(self: Vec3, other: Vec3) -> Vec3 =
        Vec3 { x: self.x + other.x, y: self.y + other.y, z: self.z + other.z }

fn main() -> i32 =
    // With-builder form: build Config with mutations
    let cfg = with Config {} as mut c:
        c.width = 1920
        c.height = 1080
        c.fullscreen = true
    assert(cfg.width == 1920)
    assert(cfg.height == 1080)
    assert(cfg.depth == 32)
    assert(cfg.fullscreen)
    assert(cfg.is_hd())
    assert(cfg.pixel_count() == 2073600)

    // Record update form
    let small = { cfg with width: 640, height: 480 }
    assert(small.width == 640)
    assert(small.height == 480)
    assert(small.depth == 32)
    assert(not small.is_hd())

    // Chained record updates
    let base = Vec3 { x: 1, y: 2, z: 3 }
    let moved = { base with x: base.x + 10 }
    assert(moved.x == 11)
    assert(moved.y == 2)
    assert(moved.z == 3)

    let moved2 = { moved with y: moved.y + 20 }
    assert(moved2.x == 11)
    assert(moved2.y == 22)
    assert(moved2.z == 3)

    // Method on updated struct
    assert(base.length_sq() == 14)
    let scaled = { base with x: 3, y: 4, z: 0 }
    assert(scaled.length_sq() == 25)

    // With-builder returning expression
    let val = with Vec3 { x: 0, y: 0, z: 0 } as mut v:
        v.x = 10
        v.y = 20
        v.z = 30
        v.x + v.y + v.z
    assert(val == 60)

    println("all with_record_methods tests passed")
    0
