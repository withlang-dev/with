//! expect-error: bare 'Idle' names both a field of the receiver `Gauge` and the variant `Idle` (§9.5)

// §9.5 (#1930): a bare name that resolves to a receiver field and to a
// variant in scope is an error at that use; `self.Idle` and `Mode.Idle`
// reach each.

enum Mode { | Idle | Busy }

type Gauge {
    Idle: i32,
}

impl Gauge:
    fn get -> i32: Idle

fn main:
    print(f"{Gauge { Idle: 1 }.get()}")
