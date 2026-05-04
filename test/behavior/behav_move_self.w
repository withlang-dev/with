// move self method invalidates receiver at call site

type Counter { value: i32 }

impl Counter:
    fn into_value(move self: Self) -> i32:
        self.value

fn main:
    let c = Counter { value: 42 }
    let v = c.into_value()   // c is consumed here
    assert(v == 42)
    // c is no longer accessible after this point
    print("ok\n")
