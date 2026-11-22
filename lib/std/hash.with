// std.hash — hashing.
//
// `hash_of` is the hash a `HashMap` gives a key (§11.7, D96): seeded once
// per process, consistent with the key's `==`, for a container a library
// writes over a generic key. The helpers after it are deterministic 64-bit
// hashes of scalars, the same on every run.

/// The hash the standard maps give `key`.
pub fn hash_of[K: Key](key: &K) -> u64: with_key_hash[K](key)

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
