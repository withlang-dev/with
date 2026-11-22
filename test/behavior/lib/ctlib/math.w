// A package whose functions another package evaluates at compile time.
// `comptime fn` is the author's promise that a function stays evaluable;
// inside the package no marker is needed, so `helper` has none.

pub comptime fn squared(n: i32) -> i32: n * n

pub comptime fn cubed(n: i32) -> i32: n * helper(n)

fn helper(n: i32) -> i32: n * n

pub fn plain(n: i32) -> i32: n + 1

pub type Pair:
    pub a: i32
    pub b: i32

impl Pair:
    pub comptime fn sum() -> i32: self.a + self.b
    pub fn product() -> i32: self.a * self.b

// An operator, a trait method and a generic function are functions too:
// each with the marker, and each without.
pub type Money:
    pub cents: i32

impl Money:
    pub comptime fn add(other: &Money) -> Money: Money { cents: self.cents + other.cents }
    pub fn sub(other: &Money) -> Money: Money { cents: self.cents - other.cents }

pub trait Scaled:
    fn scaled(self: &Self, k: i32) -> i32

impl Scaled for Money:
    comptime fn scaled(self: &Self, k: i32) -> i32: self.cents * k

pub comptime fn first_of[T](a: T, b: T) -> T: a

pub fn second_of[T](a: T, b: T) -> T: b
