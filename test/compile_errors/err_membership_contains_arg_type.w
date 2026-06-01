//! expect-error: wrong argument type in call to 'Whitelist.contains'

type Whitelist { allowed: HashSet[i32] }

impl Contains[i32] for Whitelist =
    fn contains(self: &Self, value: &i32) -> bool:
        *value in self.allowed

fn main:
    let wl = Whitelist { allowed: HashSet.new() }
    let _ = "x" in wl
