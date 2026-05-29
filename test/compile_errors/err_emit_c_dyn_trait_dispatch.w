//! args: --emit-c
//! expect-build-fail: C backend does not yet support dyn trait method dispatch

trait Greet:
    fn hello(self: &Self) -> str

type English {}

impl Greet for English:
    fn hello(self: &Self) -> str: "Hello"

fn accept(g: &dyn Greet) -> str:
    g.hello()

fn main:
    let eng = English {}
    let _ = accept(&eng)
