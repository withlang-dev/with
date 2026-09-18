//! ct_positive: static dispatch + default method + dyn dispatch happy path.
//! expect-stdout: ct-ok

trait Describable:
    fn describe(self: &Self) -> str
    fn loud(self: &Self) -> str:
        "loud"

type Circle { radius: i32 }

impl Describable for Circle:
    fn describe(self: &Self) -> str:
        "circle"

fn shout(d: &dyn Describable) -> str:
    d.describe()

fn main:
    let c = Circle { radius: 5 }
    assert(c.describe() == "circle")
    assert(c.loud() == "loud")
    assert(shout(&c) == "circle")
    print("ct-ok")
