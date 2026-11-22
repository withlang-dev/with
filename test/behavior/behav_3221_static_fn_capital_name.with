//! expect-stdout: 1 2

// #3221: a static function whose name starts with a capital. `.Bar` is one
// dot-identifier token, and the function-name parser looked for a `.`.
type Foo { n: i32 }

fn Foo.Bar() -> Foo: Foo { n: 1 }

impl Foo:
    fn Twice() -> i32: self.n * 2

fn main:
    let f = Foo.Bar()
    print(f"{f.n} {f.Twice()}")
