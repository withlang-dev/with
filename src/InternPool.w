// Wave 1 foundations: unified intern pool.
//
// InternPool is a thin handle wrapping a heap-allocated state block.
// Copies of InternPool share the same underlying data — Vec growth
// in one copy is visible to all. This is critical because Sema stores
// InternPool by value and passes self by value on every method call.

use compiler.foundation.Types
use compiler.foundation.Values
use std.collections.HashMap

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_hashmap_new_at(base: &i8, offset: i64, key_size: i64, val_size: i64) -> Unit
extern fn with_getenv_str(name: &str) -> str
extern fn with_eprint(s: &str) -> Unit
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> *mut u8
extern fn with_alloc(size: i64) -> *mut u8

fn intern_debug_init_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_STAGE1_TRACE")
    if raw.len() == 0:
        return 0
    1

fn intern_debug_init(msg: &str):
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

impl InternStringArena:
    mut fn store(s: &str) -> str:
        if s.len() == 0:
            return ""
        let src = unsafe **(&s as *const *const *const u8)
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
        unsafe *((dest as i64 + len) as *mut u8) = 0
        self.offset = self.offset + need
        var raw: [2]i64 = [dest as i64, len]
        let p = &raw as *const str
        unsafe *p

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

pub type InternPool {
    state: *mut InternPoolState,
}
impl Copy for InternPool

fn intern_new_map_str_i32 -> HashMap[str, i32]:
    let map: HashMap[str, i32] = HashMap.new()
    map

fn InternPool.init -> InternPool:
    intern_debug_init("InternPool.init:start")
    let ptr = with_alloc(256) as *mut InternPoolState
    unsafe *ptr = InternPoolState {
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

impl InternPool:
    fn deinit():
        return

    fn intern_str(s: &str) -> Symbol:
        let st = self.state
        let existing = st.symbol_map.get(s)
        if existing.is_some():
            return existing.unwrap()

        // symbol_map is authoritative: every symbol_texts entry is inserted
        // into symbol_map at this same site, so a map miss means the symbol is
        // new. (No linear-scan fallback — it never matched over a full compile.)
        let id = st.symbol_texts.len() as i32
        let owned = st.strings.store(s)
        st.symbol_map.insert(with_str_clone_ref(owned), id)
        st.symbol_texts.push(owned)
        id

    fn resolve_symbol(sym: Symbol) -> &str:
        if sym <= 0 or sym >= self.state.symbol_texts.len() as i32:
            return ""
        self.state.symbol_texts.get(sym as i64)

    fn intern_type(key: TypeKey) -> TypeId:
        let st = self.state
        let canon = type_key_to_string(key)
        let existing = st.type_map.get(canon)
        if existing.is_some():
            return existing.unwrap() as TypeId

        let id = st.type_keys.len() as i32
        st.type_keys.push(key)
        st.type_map.insert(st.strings.store(canon), id)
        id as TypeId

    fn resolve_type(id: TypeId) -> TypeKey:
        let st = self.state
        if id <= 0 or id >= st.type_keys.len() as i32:
            return type_key_invalid()
        type_key_clone(st.type_keys.get(id as i64))

    fn intern_value(key: ValueKey) -> ValueId:
        let st = self.state
        let canon = value_key_to_string(key)
        let existing = st.value_map.get(canon)
        if existing.is_some():
            return existing.unwrap() as ValueId

        let id = st.value_keys.len() as i32
        st.value_keys.push(key)
        st.value_map.insert(st.strings.store(canon), id)
        id

    fn resolve_value(id: ValueId) -> ValueKey:
        let st = self.state
        if id <= 0 or id >= st.value_keys.len() as i32:
            return value_key_invalid()
        value_key_clone(st.value_keys.get(id as i64))

    fn symbol_count() -> i32:
        (self.state.symbol_texts.len() as i32) - 1

    fn type_count() -> i32:
        (self.state.type_keys.len() as i32) - 1

    fn value_count() -> i32:
        (self.state.value_keys.len() as i32) - 1

    // Legacy compatibility entrypoints used throughout current parser/sema/codegen.
    fn intern(s: &str) -> Symbol:
        self.intern_str(s)

    fn resolve(sym: Symbol) -> &str:
        self.resolve_symbol(sym)
