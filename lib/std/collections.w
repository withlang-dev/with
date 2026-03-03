// std.collections — collection conveniences in pure With.
//
// Core collection types (Vec, HashMap, HashSet) are language built-ins.
// This module adds generic helper functions over those built-ins.

pub fn update(map: HashMap[str, i32], key: str, default_value: i32, f: fn(i32) -> i32) -> void:
    map.update(key, default_value, f)

pub fn increment(map: HashMap[str, i32], key: str) -> void:
    map.increment(key)

pub fn decrement(map: HashMap[str, i32], key: str) -> void:
    map.decrement(key)

pub fn append(map: HashMap[str, Vec[i32]], key: str, value: i32) -> void:
    map.append(key, value)

pub fn sequence_option(xs: Vec[?i32]) -> ?Vec[i32]:
    xs.sequence()

pub fn sequence_result(xs: Vec[Result[i32, i32]]) -> Result[Vec[i32], i32]:
    xs.sequence()

// --- Additional collections (concrete scaffolding) ---

extern fn with_i32_to_str(n: i32) -> str

type Handle = {
    key: str,
    generation: i32,
}

type SlotMap = {
    generations: HashMap[str, i32],
    values: HashMap[str, i32],
}

pub fn slotmap_new -> SlotMap:
    SlotMap {
        generations: HashMap.new(),
        values: HashMap.new(),
    }

pub fn slotmap_insert(map: SlotMap, value: i32) -> (SlotMap, Handle):
    let key = map.generations.len() as i32 |> with_i32_to_str
    let generation_value = map.generations.get(key).unwrap_or(0) + 1
    map.generations.insert(key, generation_value)
    map.values.insert(key, value)
    (map, Handle { key: key, generation: generation_value })

pub fn slotmap_get(map: SlotMap, h: Handle) -> ?i32:
    let g = map.generations.get(h.key)
    if g.is_none() then map.values.get("__with_slotmap_absent__")
    else if g.unwrap() != h.generation then map.values.get("__with_slotmap_absent__")
    else map.values.get(h.key)

pub fn slotmap_contains(map: SlotMap, h: Handle) -> bool:
    let g = map.generations.get(h.key)
    if g.is_none() then false
    else if g.unwrap() != h.generation then false
    else map.values.get(h.key).is_some()

pub fn slotmap_remove(map: SlotMap, h: Handle) -> (SlotMap, bool):
    let g = map.generations.get(h.key)
    if g.is_none() then (map, false)
    else if g.unwrap() != h.generation then (map, false)
    else
        let removed = map.values.remove(h.key)
        if removed:
            map.generations.insert(h.key, h.generation + 1)
        (map, removed)

pub fn slotmap_len(map: SlotMap) -> i32:
    map.values.len() as i32

type BTreeMap = {
    inner: HashMap[str, i32],
}

pub fn btree_new -> BTreeMap:
    BTreeMap { inner: HashMap.new() }

pub fn btree_insert(map: BTreeMap, key: str, value: i32) -> BTreeMap:
    map.inner.insert(key, value)
    map

pub fn btree_get(map: BTreeMap, key: str) -> ?i32:
    map.inner.get(key)

pub fn btree_contains(map: BTreeMap, key: str) -> bool:
    map.inner.contains(key)

pub fn btree_remove(map: BTreeMap, key: str) -> (BTreeMap, bool):
    let removed = map.inner.remove(key)
    (map, removed)

pub fn btree_len(map: BTreeMap) -> i64:
    map.inner.len()
