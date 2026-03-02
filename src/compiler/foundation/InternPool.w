// Wave 1 foundations: unified intern pool.
//
// Single source of truth for interned symbols, types, and values.
// Identity is ID-based, and canonicalization is key-string based.

use compiler.foundation.Ids
use compiler.foundation.Types
use compiler.foundation.Values

type InternPool = {
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

fn InternPool.init -> InternPool:
    var p = InternPool {
        symbol_texts: Vec.new(),
        symbol_map: HashMap.new(),
        type_keys: Vec.new(),
        type_map: HashMap.new(),
        value_keys: Vec.new(),
        value_map: HashMap.new(),
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
