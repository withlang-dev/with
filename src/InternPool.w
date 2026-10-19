// Wave 1 foundations: unified intern pool.
//
// InternPool is a counted handle over a heap-allocated state block (#2449).
// Every handle is a holder: `clone()` makes another, dropping one releases
// it, and the release that finds no other holder frees the symbols, the
// maps and the string arena. Interning through any handle is visible
// through every other (the pool is append-only, so sharing is benign); a
// function that only reads or interns takes `&InternPool`, a type that
// keeps a handle stores a clone, and one owner per compilation holds the
// original. Nothing leaks: the last handle out frees the block.

use compiler.foundation.Types
use compiler.foundation.Values
use std.collections.HashMap

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_getenv_str(name: &str) -> str
extern fn with_eprint(s: &str) -> Unit
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> *mut u8
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8)

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
pub type TypeId = i32
type ValueId = i32

// ── String arena ──────────────────────────────────────────────────
// Append-only page chain for interned string data. Pages are never
// freed or moved while the pool lives, so pointers into the arena are
// stable for the pool's lifetime; the arena's drop frees them. Every
// string sits at least INTERN_PAGE_LEAD bytes into its page: a str whose
// payload started a page would read as an owned allocation to the
// runtime's holder count (rt_payload_start_is_owned), and its copies
// would then retain and release the page itself.

const INTERN_PAGE_SIZE = 1048576  // 1MB per page
const INTERN_PAGE_LEAD = 16

type InternStringArena {
    pages: List[*mut u8],
    offset: i64,
}

fn InternStringArena.new() -> InternStringArena:
    let first = with_alloc(INTERN_PAGE_SIZE)
    var arena = InternStringArena { pages: List.new(), offset: INTERN_PAGE_LEAD }
    arena.pages.push(first)
    arena

impl Drop for InternStringArena:
    move fn drop():
        for i in 0..self.pages.len():
            with_free(self.pages[i])

impl InternStringArena:
    mut fn store(s: &str) -> str:
        if s.len() == 0:
            return ""
        let src = unsafe *(s as *const str as *const *const u8)
        let len = s.len()
        let need = len + 1
        if self.offset + need > INTERN_PAGE_SIZE:
            let page_size = if INTERN_PAGE_LEAD + need > INTERN_PAGE_SIZE: INTERN_PAGE_LEAD + need else: INTERN_PAGE_SIZE
            let page = with_alloc(page_size)
            self.pages.push(page)
            self.offset = INTERN_PAGE_LEAD
        let page = self.pages[self.pages.len() - 1]
        let dest = (page as i64 + self.offset) as *mut u8
        with_memcpy(dest, src, len)
        unsafe *((dest as i64 + len) as *mut u8) = 0
        self.offset = self.offset + need
        var raw: [2]i64 = [dest as i64, len]
        let p = &raw as *const str
        unsafe *p

// ── InternPool ────────────────────────────────────────────────────

type InternPoolState {
    holders: i64,
    symbol_texts: List[str],
    symbol_map: HashMap[str, i32],
    strings: InternStringArena,
    type_keys: List[TypeKey],
    type_map: HashMap[str, i32],
    value_keys: List[ValueKey],
    value_map: HashMap[str, i32],
}

type InternPool {
    state: *mut InternPoolState,
}

fn intern_new_map_str_i32 -> HashMap[str, i32]:
    let map: HashMap[str, i32] = HashMap.new()
    map

fn InternPool.init -> InternPool:
    intern_debug_init("InternPool.init:start")
    let ptr = with_alloc(sizeof[InternPoolState]()) as *mut InternPoolState
    unsafe *ptr = InternPoolState {
        holders: 1,
        symbol_texts: List.new(),
        symbol_map: intern_new_map_str_i32(),
        strings: InternStringArena.new(),
        type_keys: List.new(),
        type_map: intern_new_map_str_i32(),
        value_keys: List.new(),
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

impl Drop for InternPool:
    move fn drop():
        let st = self.state
        if st as i64 == 0:
            return
        if st.holders > 1:
            st.holders = st.holders - 1
            return
        let block = unsafe *st
        drop(block)
        with_free(st as *mut u8)

impl InternPool:
    // Another holder of the same pool: a type that keeps the handle stores
    // this; a function that only reads takes `&InternPool`.
    fn clone() -> InternPool:
        let st = self.state
        st.holders = st.holders + 1
        InternPool { state: self.state }

    fn holders() -> i64:
        self.state.holders

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
        if sym <= 0 or sym >= self.state.symbol_texts.len():
            return ""
        self.state.symbol_texts[sym]

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
        if id <= 0 or id >= st.type_keys.len():
            return type_key_invalid()
        type_key_clone(st.type_keys[id])

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
        if id <= 0 or id >= st.value_keys.len():
            return value_key_invalid()
        value_key_clone(st.value_keys[id])

    fn symbol_count() -> i32:
        (self.state.symbol_texts.len() - 1) as i32

    fn type_count() -> i32:
        (self.state.type_keys.len() - 1) as i32

    fn value_count() -> i32:
        (self.state.value_keys.len() - 1) as i32

    // Legacy compatibility entrypoints used throughout current parser/sema/codegen.
    fn intern(s: &str) -> Symbol:
        self.intern_str(s)

    // The symbol for a text that is already interned, or 0: the on-demand
    // interface merge asks whether the source could spell a name at all.
    fn lookup_symbol(s: &str) -> Symbol:
        let existing = self.state.symbol_map.get(s)
        if existing.is_some(): existing.unwrap() else: 0

    fn resolve(sym: Symbol) -> &str:
        self.resolve_symbol(sym)
