module ecs.math

// --- Vec2: 2D vector ---

pub type Vec2 { x: f32, y: f32 }
impl Copy for Vec2

// Constructors and binary helpers have no receiver, so they are
// functions of the type (§3.1).
pub fn Vec2.zero -> Vec2: Vec2 { x: 0.0, y: 0.0 }
pub fn Vec2.new(x: f32, y: f32) -> Vec2: Vec2 { x, y }
pub fn Vec2.one -> Vec2: Vec2 { x: 1.0, y: 1.0 }

pub fn Vec2.dot(a: Vec2, b: Vec2) -> f32: a.x * b.x + a.y * b.y
pub fn Vec2.distance_sq(a: Vec2, b: Vec2) -> f32: a.sub(b).length_sq()
pub fn Vec2.distance(a: Vec2, b: Vec2) -> f32: Vec2.distance_sq(a, b).sqrt()

extend Vec2:
    pub fn length_sq() -> f32: self.x * self.x + self.y * self.y
    pub fn length() -> f32: self.length_sq().sqrt()

    pub fn normalized() -> Vec2:
        with self.length() as len:
            if len > 1e-6: Vec2 { x: self.x / len, y: self.y / len }
            else: Vec2.zero()

    pub fn scale(s: f32) -> Vec2:
        Vec2 { x: self.x * s, y: self.y * s }

    pub fn add(other: Vec2) -> Vec2: Vec2 { x: self.x + other.x, y: self.y + other.y }
    pub fn sub(other: Vec2) -> Vec2: Vec2 { x: self.x - other.x, y: self.y - other.y }
    pub fn neg() -> Vec2: Vec2 { x: -self.x, y: -self.y }

// --- AABB: axis-aligned bounding box ---

pub type AABB { min: Vec2, max: Vec2 }
impl Copy for AABB

pub fn AABB.from_center(center: Vec2, half_size: Vec2) -> AABB:
    AABB { min: center.sub(half_size), max: center.add(half_size) }

extend AABB:
    pub fn overlaps(other: &AABB) -> bool:
        self.min.x <= other.max.x and self.max.x >= other.min.x and
        self.min.y <= other.max.y and self.max.y >= other.min.y

    pub fn center() -> Vec2:
        Vec2.new(
            (self.min.x + self.max.x) * 0.5,
            (self.min.y + self.max.y) * 0.5,
        )

    pub fn size() -> Vec2:
        Vec2.new(self.max.x - self.min.x, self.max.y - self.min.y)
