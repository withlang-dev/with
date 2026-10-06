fn private_fn -> i32:
    1

type PrivateType {
    value: i32,
}

const PRIVATE_CONST = 2

global PRIVATE_GLOBAL = 3


// #2186 (§18.3): a public type whose methods differ in visibility. `secret`
// is private to this module; `open` is public; `show` is reached through
// the public trait `Show`.
pub type Gauge { n: i32 }

impl Gauge:
    fn secret(): self.n
    pub fn open(): self.secret() + 1

pub trait Show:
    fn show(self: &Self) -> i32

impl Show for Gauge:
    fn show(): self.n * 10

// D100 (§18.3, #2209): a public type whose fields differ in visibility.
pub type Sealed { secret: i32, pub open: i32 }
pub fn make_sealed() -> Sealed: Sealed { secret: 1, open: 2 }
