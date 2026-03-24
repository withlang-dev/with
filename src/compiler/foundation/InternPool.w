// Wave 1 foundations: unified intern pool.
//
// Single source of truth for interned symbols, types, and values.
// Identity is ID-based, and canonicalization is key-string based.

use compiler.foundation.Ids
use compiler.foundation.Types
use compiler.foundation.Values

extern fn with_hashmap_new_at(base: &T, offset: i64, key_size: i64, val_size: i64) -> void

type InternPool {
    // Symbols
    symbol_texts: Vec[str],
    symbol_map: HashMap[str, i32],

    // Types
    type_keys: Vec[TypeKey],
    type_map: HashMap[str, i32],

    // Values
    value_keys: Vec[ValueKey],
    value_map: HashMap[str, i32],
}

fn foundation_new_map_str_i32 -> HashMap[str, i32]:
    let map: HashMap[str, i32] = HashMap.new()
    map

fn foundation_intern_text_eq(a: str, b: str) -> bool:
    if a.len() != b.len():
        return false
    var i = 0
    while i < a.len() as i32:
        if a.byte_at(i as i64) != b.byte_at(i as i64):
            return false
        i = i + 1
    true

fn InternPool.init -> InternPool:
    let symbol_texts: Vec[str] = Vec.new()
    let type_keys: Vec[TypeKey] = Vec.new()
    let value_keys: Vec[ValueKey] = Vec.new()
    let symbol_map = foundation_new_map_str_i32()
    let type_map = foundation_new_map_str_i32()
    let value_map = foundation_new_map_str_i32()
    var p = InternPool {
        symbol_texts,
        symbol_map,
        type_keys,
        type_map,
        value_keys,
        value_map,
    }

    // Reserve index 0 as sentinel for each lane.
    p.symbol_texts.push("")
    p.type_keys.push(type_key_invalid())
    p.value_keys.push(value_key_invalid())
    p

fn InternPool.intern_str(self: InternPool, s: str) -> Symbol:
    let existing = self.symbol_map.get(s)
    if existing.is_some():
        return symbol_from_raw(existing.unwrap())

    var raw = 1
    while raw < self.symbol_texts.len() as i32:
        let existing_text = self.symbol_texts.get(raw as i64)
        if foundation_intern_text_eq(existing_text, s):
            self.symbol_map.insert(existing_text, raw)
            return symbol_from_raw(raw)
        raw = raw + 1

    let id = self.symbol_texts.len() as i32
    self.symbol_texts.push(s)
    self.symbol_map.insert(s, id)
    symbol_from_raw(id)

fn InternPool.resolve_symbol(self: InternPool, sym: Symbol) -> str:
    if not symbol_is_valid(sym):
        return ""
    let raw = symbol_raw(sym)
    if raw <= 0 or raw >= self.symbol_texts.len() as i32:
        return ""
    self.symbol_texts.get(raw as i64)

fn InternPool.intern_type(self: InternPool, key: TypeKey) -> TypeId:
    let canon = type_key_to_string(key)
    let existing = self.type_map.get(canon)
    if existing.is_some():
        return type_id_from_raw(existing.unwrap())

    let id = self.type_keys.len() as i32
    self.type_keys.push(key)
    self.type_map.insert(canon, id)
    type_id_from_raw(id)

fn InternPool.resolve_type(self: InternPool, id: TypeId) -> TypeKey:
    if not type_id_is_valid(id):
        return type_key_invalid()
    let raw = type_id_raw(id)
    if raw <= 0 or raw >= self.type_keys.len() as i32:
        return type_key_invalid()
    self.type_keys.get(raw as i64)

fn InternPool.intern_value(self: InternPool, key: ValueKey) -> ValueId:
    let canon = value_key_to_string(key)
    let existing = self.value_map.get(canon)
    if existing.is_some():
        return value_id_from_raw(existing.unwrap())

    let id = self.value_keys.len() as i32
    self.value_keys.push(key)
    self.value_map.insert(canon, id)
    value_id_from_raw(id)

fn InternPool.resolve_value(self: InternPool, id: ValueId) -> ValueKey:
    if not value_id_is_valid(id):
        return value_key_invalid()
    let raw = value_id_raw(id)
    if raw <= 0 or raw >= self.value_keys.len() as i32:
        return value_key_invalid()
    self.value_keys.get(raw as i64)

fn InternPool.symbol_count(self: InternPool) -> i32:
    (self.symbol_texts.len() as i32) - 1

fn InternPool.type_count(self: InternPool) -> i32:
    (self.type_keys.len() as i32) - 1

fn InternPool.value_count(self: InternPool) -> i32:
    (self.value_keys.len() as i32) - 1
