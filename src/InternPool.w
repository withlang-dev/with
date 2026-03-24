// Wave 1 foundations: unified intern pool.
//
// Root `InternPool` now follows the foundation layout while preserving
// historical string-only entrypoints used across existing compiler code.

use compiler.foundation.Types
use compiler.foundation.Values

extern fn with_hashmap_new_at(base: &i8, offset: i64, key_size: i64, val_size: i64) -> void
extern fn with_getenv_str(name: str) -> str
extern fn with_eprintln(s: str) -> void

fn intern_debug_init_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_STAGE1_TRACE")
    if raw.len() == 0:
        return 0
    1

fn intern_debug_init(msg: str):
    if intern_debug_init_enabled() == 0:
        return
    with_eprintln("[intern-init] " ++ msg)

type Symbol = i32
type TypeId = i32
type ValueId = i32

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

fn intern_new_map_str_i32 -> HashMap[str, i32]:
    intern_debug_init("intern_new_map_str_i32:start")
    let map: HashMap[str, i32] = HashMap.new()
    intern_debug_init("intern_new_map_str_i32:new_out")
    map

fn intern_text_eq(a: str, b: str) -> bool:
    if a.len() != b.len():
        return false
    var i = 0
    while i < a.len() as i32:
        if a.byte_at(i as i64) != b.byte_at(i as i64):
            return false
        i = i + 1
    true

fn InternPool.init -> InternPool:
    intern_debug_init("InternPool.init:start")
    let symbol_texts: Vec[str] = Vec.new()
    intern_debug_init("InternPool.init:symbol_texts")
    let type_keys: Vec[TypeKey] = Vec.new()
    intern_debug_init("InternPool.init:type_keys")
    let value_keys: Vec[ValueKey] = Vec.new()
    intern_debug_init("InternPool.init:value_keys")
    let symbol_map = intern_new_map_str_i32()
    intern_debug_init("InternPool.init:symbol_map")
    let type_map = intern_new_map_str_i32()
    intern_debug_init("InternPool.init:type_map")
    let value_map = intern_new_map_str_i32()
    intern_debug_init("InternPool.init:value_map")
    var p = InternPool {
        symbol_texts,
        symbol_map,
        type_keys,
        type_map,
        value_keys,
        value_map,
    }
    intern_debug_init("InternPool.init:assembled")

    // Reserve index 0 as sentinel for each lane.
    p.symbol_texts.push("")
    intern_debug_init("InternPool.init:sentinel_symbols")
    p.type_keys.push(type_key_invalid())
    intern_debug_init("InternPool.init:sentinel_types")
    p.value_keys.push(value_key_invalid())
    intern_debug_init("InternPool.init:sentinel_values")
    p

fn InternPool.new -> InternPool:
    InternPool.init()

fn InternPool.deinit(self: InternPool):
    // No-op in current runtime model.
    return

fn InternPool.intern_str(self: InternPool, s: str) -> Symbol:
    let existing = self.symbol_map.get(s)
    if existing.is_some():
        return existing.unwrap()

    var i = 1
    while i < self.symbol_texts.len() as i32:
        let existing_text = self.symbol_texts.get(i as i64)
        if intern_text_eq(existing_text, s):
            self.symbol_map.insert(existing_text, i)
            return i
        i = i + 1

    let id = self.symbol_texts.len() as i32
    self.symbol_texts.push(s)
    self.symbol_map.insert(s, id)
    id

fn InternPool.resolve_symbol(self: InternPool, sym: Symbol) -> str:
    if sym <= 0 or sym >= self.symbol_texts.len() as i32:
        return ""
    self.symbol_texts.get(sym as i64)

fn InternPool.intern_type(self: InternPool, key: TypeKey) -> TypeId:
    let canon = type_key_to_string(key)
    let existing = self.type_map.get(canon)
    if existing.is_some():
        return existing.unwrap()

    let id = self.type_keys.len() as i32
    self.type_keys.push(key)
    self.type_map.insert(canon, id)
    id

fn InternPool.resolve_type(self: InternPool, id: TypeId) -> TypeKey:
    if id <= 0 or id >= self.type_keys.len() as i32:
        return type_key_invalid()
    self.type_keys.get(id as i64)

fn InternPool.intern_value(self: InternPool, key: ValueKey) -> ValueId:
    let canon = value_key_to_string(key)
    let existing = self.value_map.get(canon)
    if existing.is_some():
        return existing.unwrap()

    let id = self.value_keys.len() as i32
    self.value_keys.push(key)
    self.value_map.insert(canon, id)
    id

fn InternPool.resolve_value(self: InternPool, id: ValueId) -> ValueKey:
    if id <= 0 or id >= self.value_keys.len() as i32:
        return value_key_invalid()
    self.value_keys.get(id as i64)

fn InternPool.symbol_count(self: InternPool) -> i32:
    (self.symbol_texts.len() as i32) - 1

fn InternPool.type_count(self: InternPool) -> i32:
    (self.type_keys.len() as i32) - 1

fn InternPool.value_count(self: InternPool) -> i32:
    (self.value_keys.len() as i32) - 1

// Legacy compatibility entrypoints used throughout current parser/sema/codegen.
fn InternPool.intern(self: InternPool, s: str) -> Symbol:
    self.intern_str(s)

fn InternPool.resolve(self: InternPool, sym: Symbol) -> str:
    self.resolve_symbol(sym)
