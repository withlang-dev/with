//! expect-check-fail: `Minted` hashes an integer ID the program minted; `str` keys stay seeded (§11.7, D196)

// D196: a str key is text the program received, whatever the map's owner
// thinks of it; only an integer ID may name the unseeded hasher.
use std.collections.HashMap
use std.collections.Minted

fn main:
    var names: HashMap[str, i32, Minted] = HashMap.new()
    names.insert("a", 1)
    print(f"{names.len()}")
