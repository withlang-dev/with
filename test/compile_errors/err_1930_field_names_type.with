//! expect-error: bare 'Meter' names both a field of the receiver `Gauge` and the type `Meter` (§9.5)

// §9.5 (#1930): a bare name that resolves to a receiver field and to a type
// in scope is an error at that use; `self.Meter` reaches the field.

type Meter { v: i32 }

type Gauge {
    Meter: i32,
}

impl Gauge:
    fn get -> i32: Meter

fn main:
    print(f"{Gauge { Meter: 1 }.get()}")
