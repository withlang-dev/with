// std.collections — collection conveniences in pure With.
//
// Core collection types (Vec, HashMap, HashSet) are language built-ins.
// This module adds generic helper functions over those built-ins.

pub fn update[K, V](map: HashMap[K, V], key: K, default_value: V, f: fn(V) -> V) -> void =
    map.update(key, default_value, f)

pub fn increment[K](map: HashMap[K, i32], key: K) -> void =
    map.increment(key)

pub fn decrement[K](map: HashMap[K, i32], key: K) -> void =
    map.decrement(key)

pub fn append[K, V](map: HashMap[K, Vec[V]], key: K, value: V) -> void =
    map.append(key, value)
