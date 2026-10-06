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
