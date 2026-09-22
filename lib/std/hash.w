// std.hash — pure-With hash helpers.
//
// Provides deterministic 64-bit hash utilities for common scalar inputs.

pub type Hasher {
    state: i64,
}

pub type DefaultHasher = Hasher

pub fn combine(seed: i64, value: i64) -> i64:
    (seed *% 1099511628211) ^ value

pub fn hash_i64(value: i64) -> i64:
    combine(1469598103934665603, value)

pub fn hash_pair(a: i64, b: i64) -> i64:
    combine(hash_i64(a), b)

pub fn hash_str(s: str) -> i64:
    var h: i64 = 1469598103934665603
    var i: i64 = 0
    while i < s.len():
        h = combine(h, s[i])
        i = i + 1
    h

pub fn hasher -> Hasher:
    Hasher { state: 1469598103934665603 }

pub fn default_hasher -> DefaultHasher:
    hasher()

impl Hasher:
    mut fn update_i64(value: i64): self.state = combine(self.state, value)

    mut fn update_str(s: str):
        var i: i64 = 0
        while i < s.len():
            self.state = combine(self.state, s[i])
            i = i + 1

    fn finish(): self.state
