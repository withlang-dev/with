// Wave 1 foundations: unified intern pool.
//
// Single source of truth for interned symbols, types, and values.
// Heap-indirected so copies share state (same fix as src/InternPool.w).

use compiler.foundation.Ids
use compiler.foundation.Types
use compiler.foundation.Values
use std.collections.HashMap

extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> *mut u8
extern fn with_alloc(size: i64) -> *mut u8

let FND_INTERN_PAGE_SIZE: i64 = 1048576

pub type FndInternStringArena {
    pages: Vec[*mut u8],
    offset: i64,
}

fn FndInternStringArena.new() -> FndInternStringArena:
    let first = with_alloc(FND_INTERN_PAGE_SIZE)
    var arena = FndInternStringArena { pages: Vec.new(), offset: 0 }
    arena.pages.push(first)
    arena

fn FndInternStringArena.store(mut self: FndInternStringArena, s: &str) -> str:
    if s.len() == 0:
        return ""
    let src = unsafe **(&s as *const *const *const u8)
    let len = s.len()
    let need = len + 1
    if self.offset + need > FND_INTERN_PAGE_SIZE:
        let page_size = if need > FND_INTERN_PAGE_SIZE: need else: FND_INTERN_PAGE_SIZE
        let page = with_alloc(page_size)
        self.pages.push(page)
        self.offset = 0
    let page = self.pages.get(self.pages.len() - 1)
    let dest = (page as i64 + self.offset) as *mut u8
    with_memcpy(dest, src, len)
    unsafe *((dest as i64 + len) as *mut u8) = 0
    self.offset = self.offset + need
    var raw: [2]i64 = [dest as i64, len]
    let p = &raw as *const str
    unsafe *p

pub type InternPoolState {
    symbol_texts: Vec[str],
    symbol_map: HashMap[str, i32],
    strings: FndInternStringArena,
    type_keys: Vec[TypeKey],
    type_map: HashMap[str, i32],
    value_keys: Vec[ValueKey],
    value_map: HashMap[str, i32],
}

pub type InternPool {
    state: *mut InternPoolState,
}
impl Copy for InternPool

fn foundation_new_map_str_i32 -> HashMap[str, i32]:
    let map: HashMap[str, i32] = HashMap.new()
    map

fn foundation_intern_text_eq(a: &str, b: &str) -> bool:
    if a.len() != b.len():
        return false
    var i = 0
    while i < a.len() as i32:
        if a[i] != b[i]:
            return false
        i = i + 1
    true

pub fn InternPool.init -> InternPool:
    let ptr = with_alloc(256) as *mut InternPoolState
    unsafe *ptr = InternPoolState {
        symbol_texts: Vec.new(),
        symbol_map: foundation_new_map_str_i32(),
        strings: FndInternStringArena.new(),
        type_keys: Vec.new(),
        type_map: foundation_new_map_str_i32(),
        value_keys: Vec.new(),
        value_map: foundation_new_map_str_i32(),
    }
    ptr.symbol_texts.push("")
    ptr.type_keys.push(type_key_invalid())
    ptr.value_keys.push(value_key_invalid())
    InternPool { state: ptr }

pub fn InternPool.intern_str(self: &Self, s: &str) -> Symbol:
    let st = self.state
    let existing = st.symbol_map.get(s)
    if existing.is_some():
        return symbol_from_raw(existing.unwrap())

    var raw = 1
    while raw < st.symbol_texts.len() as i32:
        let existing_text = st.symbol_texts[raw]
        if foundation_intern_text_eq(existing_text, s):
            let owned_key = existing_text.clone()
            st.symbol_map.insert(owned_key, raw)
            return symbol_from_raw(raw)
        raw = raw + 1

    let id = st.symbol_texts.len() as i32
    let owned = st.strings.store(s)
    st.symbol_texts.push(owned.clone())
    st.symbol_map.insert(owned, id)
    symbol_from_raw(id)

pub fn InternPool.resolve_symbol(self: &Self, sym: Symbol) -> &str:
    if not symbol_is_valid(sym):
        return ""
    let raw = symbol_raw(sym)
    if raw <= 0 or raw >= self.state.symbol_texts.len() as i32:
        return ""
    self.state.symbol_texts[raw]

pub fn InternPool.intern_type(self: &Self, key: TypeKey) -> TypeId:
    let st = self.state
    let canon = type_key_to_string(key)
    let existing = st.type_map.get(canon)
    if existing.is_some():
        return type_id_from_raw(existing.unwrap())

    let id = st.type_keys.len() as i32
    st.type_keys.push(key)
    st.type_map.insert(st.strings.store(canon), id)
    type_id_from_raw(id)

pub fn InternPool.resolve_type(self: &Self, id: TypeId) -> TypeKey:
    if not type_id_is_valid(id):
        return type_key_invalid()
    let raw = type_id_raw(id)
    if raw <= 0 or raw >= self.state.type_keys.len() as i32:
        return type_key_invalid()
    type_key_clone(self.state.type_keys[raw])

pub fn InternPool.intern_value(self: &Self, key: ValueKey) -> ValueId:
    let st = self.state
    let canon = value_key_to_string(key)
    let existing = st.value_map.get(canon)
    if existing.is_some():
        return value_id_from_raw(existing.unwrap())

    let id = st.value_keys.len() as i32
    st.value_keys.push(key)
    st.value_map.insert(st.strings.store(canon), id)
    value_id_from_raw(id)

pub fn InternPool.resolve_value(self: &Self, id: ValueId) -> ValueKey:
    if not value_id_is_valid(id):
        return value_key_invalid()
    let raw = value_id_raw(id)
    if raw <= 0 or raw >= self.state.value_keys.len() as i32:
        return value_key_invalid()
    value_key_clone(self.state.value_keys[raw])

pub fn InternPool.symbol_count(self: &Self) -> i32:
    (self.state.symbol_texts.len() as i32) - 1

pub fn InternPool.type_count(self: &Self) -> i32:
    (self.state.type_keys.len() as i32) - 1

pub fn InternPool.value_count(self: &Self) -> i32:
    (self.state.value_keys.len() as i32) - 1
