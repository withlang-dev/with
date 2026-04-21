// Wave 1 foundations: unified intern pool.
//
// InternPool is a thin handle wrapping a heap-allocated state block.
// Copies of InternPool share the same underlying data — Vec growth
// in one copy is visible to all. This is critical because Sema stores
// InternPool by value and passes self by value on every method call.

use compiler.foundation.Types
use compiler.foundation.Values

extern fn with_hashmap_new_at(base: &i8, offset: i64, key_size: i64, val_size: i64) -> void
extern fn with_getenv_str(name: str) -> str
extern fn with_eprint(s: str) -> void
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> void
extern fn with_alloc(size: i64) -> *mut u8

fn intern_debug_init_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_STAGE1_TRACE")
    if raw.len() == 0:
        return 0
    1

fn intern_debug_init(msg: str):
    if intern_debug_init_enabled() == 0:
        return
    with_eprint("[intern-init] " ++ msg)

type Symbol = i32
type TypeId = i32
type ValueId = i32

// ── String arena ──────────────────────────────────────────────────
// Append-only page chain for interned string data. Pages are never
// freed or moved, so pointers into the arena are stable forever.

let INTERN_PAGE_SIZE: i64 = 1048576  // 1MB per page

type InternStringArena {
    pages: Vec[*mut u8],
    offset: i64,
}

fn InternStringArena.new() -> InternStringArena:
    let first = with_alloc(INTERN_PAGE_SIZE)
    var arena = InternStringArena { pages: Vec.new(), offset: 0 }
    arena.pages.push(first)
    arena

fn InternStringArena.store(self: InternStringArena, s: str) -> str:
    if s.len() == 0:
        return ""
    let src = unsafe: *(&s as *const *const u8)
    let len = s.len()
    let need = len + 1
    if self.offset + need > INTERN_PAGE_SIZE:
        let page_size = if need > INTERN_PAGE_SIZE: need else: INTERN_PAGE_SIZE
        let page = with_alloc(page_size)
        self.pages.push(page)
        self.offset = 0
    let page = self.pages.get(self.pages.len() - 1)
    let dest = (page as i64 + self.offset) as *mut u8
    with_memcpy(dest, src, len)
    unsafe: *((dest as i64 + len) as *mut u8) = 0
    self.offset = self.offset + need
    var raw: [2]i64 = [dest as i64, len]
    let p = &raw as *const str
    unsafe: *p

// ── InternPool ────────────────────────────────────────────────────

type InternPoolState {
    symbol_texts: Vec[str],
    symbol_map: HashMap[str, i32],
    strings: InternStringArena,
    type_keys: Vec[TypeKey],
    type_map: HashMap[str, i32],
    value_keys: Vec[ValueKey],
    value_map: HashMap[str, i32],
}

type InternPool {
    state: *mut InternPoolState,
}

fn intern_new_map_str_i32 -> HashMap[str, i32]:
    let map: HashMap[str, i32] = HashMap.new()
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
    let ptr = with_alloc(256) as *mut InternPoolState
    unsafe: *ptr = InternPoolState {
        symbol_texts: Vec.new(),
        symbol_map: intern_new_map_str_i32(),
        strings: InternStringArena.new(),
        type_keys: Vec.new(),
        type_map: intern_new_map_str_i32(),
        value_keys: Vec.new(),
        value_map: intern_new_map_str_i32(),
    }
    intern_debug_init("InternPool.init:assembled")
    ptr.symbol_texts.push("")
    ptr.type_keys.push(type_key_invalid())
    ptr.value_keys.push(value_key_invalid())
    intern_debug_init("InternPool.init:done")
    InternPool { state: ptr }

fn InternPool.new -> InternPool:
    InternPool.init()

fn InternPool.deinit(self: InternPool):
    return

fn InternPool.intern_str(self: InternPool, s: str) -> Symbol:
    let st = self.state
    let existing = st.symbol_map.get(s)
    if existing.is_some():
        return existing.unwrap()

    var i = 1
    while i < st.symbol_texts.len() as i32:
        let existing_text = st.symbol_texts.get(i as i64)
        if intern_text_eq(existing_text, s):
            st.symbol_map.insert(existing_text, i)
            return i
        i = i + 1

    let id = st.symbol_texts.len() as i32
    let owned = st.strings.store(s)
    st.symbol_texts.push(owned)
    st.symbol_map.insert(owned, id)
    id

fn InternPool.resolve_symbol(self: InternPool, sym: Symbol) -> str:
    let st = self.state
    if sym <= 0 or sym >= st.symbol_texts.len() as i32:
        return ""
    st.symbol_texts.get(sym as i64)

fn InternPool.intern_type(self: InternPool, key: TypeKey) -> TypeId:
    let st = self.state
    let canon = type_key_to_string(key)
    let existing = st.type_map.get(canon)
    if existing.is_some():
        return existing.unwrap()

    let id = st.type_keys.len() as i32
    st.type_keys.push(key)
    st.type_map.insert(st.strings.store(canon), id)
    id as TypeId

fn InternPool.resolve_type(self: InternPool, id: TypeId) -> TypeKey:
    let st = self.state
    if id <= 0 or id >= st.type_keys.len() as i32:
        return type_key_invalid()
    st.type_keys.get(id as i64)

fn InternPool.intern_value(self: InternPool, key: ValueKey) -> ValueId:
    let st = self.state
    let canon = value_key_to_string(key)
    let existing = st.value_map.get(canon)
    if existing.is_some():
        return existing.unwrap()

    let id = st.value_keys.len() as i32
    st.value_keys.push(key)
    st.value_map.insert(st.strings.store(canon), id)
    id

fn InternPool.resolve_value(self: InternPool, id: ValueId) -> ValueKey:
    let st = self.state
    if id <= 0 or id >= st.value_keys.len() as i32:
        return value_key_invalid()
    st.value_keys.get(id as i64)

fn InternPool.symbol_count(self: InternPool) -> i32:
    (self.state.symbol_texts.len() as i32) - 1

fn InternPool.type_count(self: InternPool) -> i32:
    (self.state.type_keys.len() as i32) - 1

fn InternPool.value_count(self: InternPool) -> i32:
    (self.state.value_keys.len() as i32) - 1

// Legacy compatibility entrypoints used throughout current parser/sema/codegen.
fn InternPool.intern(self: InternPool, s: str) -> Symbol:
    self.intern_str(s)

fn InternPool.resolve(self: InternPool, sym: Symbol) -> str:
    self.resolve_symbol(sym)
