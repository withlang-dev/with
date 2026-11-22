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
