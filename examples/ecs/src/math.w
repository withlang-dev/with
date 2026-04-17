module ecs.math

// --- Vec2: 2D vector ---

type Vec2 { x: f32, y: f32 }
extend Vec2:
    fn zero: Vec2 { x: 0.0, y: 0.0 }
    fn new(x: f32, y: f32): Vec2 { x, y }
    fn one: Vec2 { x: 1.0, y: 1.0 }

    fn length_sq(self: &Vec2) -> f32: self.x * self.x + self.y * self.y
    fn length(self: &Vec2) -> f32: self.length_sq().sqrt()

    fn normalized(self: &Vec2) -> Vec2:
        with self.length() as len:
            if len > 1e-6 then Vec2 { x: self.x / len, y: self.y / len }
            else Vec2.zero()

    fn scale(self: &Vec2, s: f32) -> Vec2:
        Vec2 { x: self.x * s, y: self.y * s }

    fn dot(a: Vec2, b: Vec2) -> f32: a.x * b.x + a.y * b.y
    fn distance_sq(a: Vec2, b: Vec2) -> f32: (a - b).length_sq()
    fn distance(a: Vec2, b: Vec2) -> f32: Vec2.distance_sq(a, b).sqrt()

impl Add for Vec2:
    fn add(self: Vec2, other: Vec2): Vec2 { x: self.x + other.x, y: self.y + other.y }

impl Sub for Vec2:
    fn sub(self: Vec2, other: Vec2): Vec2 { x: self.x - other.x, y: self.y - other.y }

impl Neg for Vec2:
    fn neg(self: Vec2): Vec2 { x: -self.x, y: -self.y }

// --- AABB: axis-aligned bounding box ---

type AABB { min: Vec2, max: Vec2 }
extend AABB:
    fn from_center(center: Vec2, half_size: Vec2):
        AABB { min: center - half_size, max: center + half_size }

    fn overlaps(self: &AABB, other: &AABB) -> bool:
        self.min.x <= other.max.x and self.max.x >= other.min.x and
        self.min.y <= other.max.y and self.max.y >= other.min.y

    fn center(self: &AABB) -> Vec2:
        Vec2.new(
            (self.min.x + self.max.x) * 0.5,
            (self.min.y + self.max.y) * 0.5,
        )

    fn size(self: &AABB) -> Vec2:
        Vec2.new(self.max.x - self.min.x, self.max.y - self.min.y)
