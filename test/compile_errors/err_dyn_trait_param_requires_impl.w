//! expect-check-fail: does not implement trait

trait Greet:
    fn hello(self: &Self) -> str

type English {}
type French {}

impl Greet for English:
    fn hello(self: &Self) -> str: "Hello"

fn accept(_g: &dyn Greet) -> i32: 1

fn main:
    let f = French {}
    let _ = accept(&f)
