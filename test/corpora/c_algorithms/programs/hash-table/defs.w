// std.calg_testing.defs — shared definitions for migrated PCRE2

pub fn is_alpha(__with_c: i32) -> bool {
    (__with_c >= 65 and __with_c <= 90) or (__with_c >= 97 and __with_c <= 122)
}
pub fn is_digit(__with_c: i32) -> bool {
    __with_c >= 48 and __with_c <= 57
}
pub fn is_space(__with_c: i32) -> bool {
    __with_c == 32 or __with_c == 9 or __with_c == 10 or __with_c == 13 or __with_c == 12 or __with_c == 11
}
pub fn is_alnum(__with_c: i32) -> bool {
    is_alpha(__with_c) or is_digit(__with_c)
}
pub fn is_upper(__with_c: i32) -> bool {
    __with_c >= 65 and __with_c <= 90
}
pub fn is_lower(__with_c: i32) -> bool {
    __with_c >= 97 and __with_c <= 122
}
pub fn is_xdigit(__with_c: i32) -> bool {
    (__with_c >= 48 and __with_c <= 57) or (__with_c >= 65 and __with_c <= 70) or (__with_c >= 97 and __with_c <= 102)
}
pub fn is_print(__with_c: i32) -> bool {
    __with_c >= 32 and __with_c <= 126
}
pub fn to_lower(__with_c: i32) -> i32 {
    if __with_c >= 65 and __with_c <= 90 { __with_c + 32 } else { __with_c }
}
pub fn to_upper(__with_c: i32) -> i32 {
    if __with_c >= 97 and __with_c <= 122 { __with_c - 32 } else { __with_c }
}
pub extern fn strlen(s: *const i8) -> i64
pub extern fn strcmp(a: *const i8, b: *const i8) -> i32
pub extern fn strncmp(a: *const i8, b: *const i8, n: i64) -> i32
pub extern fn strchr(s: *const i8, c: i32) -> *mut i8
pub extern fn memchr(s: *const c_void, c: i32, n: i64) -> *mut c_void
pub extern fn isalpha(c: i32) -> i32
pub extern fn isdigit(c: i32) -> i32
pub extern fn isalnum(c: i32) -> i32
pub extern fn isspace(c: i32) -> i32
pub extern fn isupper(c: i32) -> i32
pub extern fn islower(c: i32) -> i32
pub extern fn isxdigit(c: i32) -> i32
pub extern fn isprint(c: i32) -> i32
pub extern fn isgraph(c: i32) -> i32
pub extern fn ispunct(c: i32) -> i32
pub extern fn iscntrl(c: i32) -> i32
pub extern fn tolower(c: i32) -> i32
pub extern fn toupper(c: i32) -> i32
pub extern fn sqrt(x: f64) -> f64
pub extern fn pow(base: f64, exp: f64) -> f64
pub extern fn floor(x: f64) -> f64
pub extern fn ceil(x: f64) -> f64
pub extern fn round(x: f64) -> f64
pub extern fn sin(x: f64) -> f64
pub extern fn cos(x: f64) -> f64
pub extern fn tan(x: f64) -> f64
pub extern fn log(x: f64) -> f64
pub extern fn log10(x: f64) -> f64
pub extern fn exp(x: f64) -> f64
pub extern fn fabs(x: f64) -> f64
pub extern fn fmod(x: f64, y: f64) -> f64
pub extern fn asin(x: f64) -> f64
pub extern fn acos(x: f64) -> f64
pub extern fn atan(x: f64) -> f64
pub extern fn atan2(y: f64, x: f64) -> f64

pub type c_void = opaque
pub extern fn abort() -> Never
pub fn __ci_unreachable() -> Never: abort()

pub type c_char = i8
pub type c_short = i16
pub type c_ushort = u16
pub type c_int = i32
pub type c_uint = u32
pub type c_long = i64
pub type c_ulong = u64
pub type c_longlong = i64
pub type c_ulonglong = u64
pub type c_longdouble = f64
pub unsafe fn __with_builtin_add_overflow_i8(__with_a: i8, __with_b: i8, __with_out: *mut i8) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_result ^ __with_a) & (__with_result ^ __with_b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i8(__with_a: i8, __with_b: i8, __with_out: *mut i8) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_a ^ __with_b) & (__with_result ^ __with_a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i8(__with_a: i8, __with_b: i8, __with_out: *mut i8) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_a == 0 or __with_b == 0: false else if __with_a == -1: __with_result == __with_b else if __with_b == -1: __with_result == __with_a else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_u8(__with_a: u8, __with_b: u8, __with_out: *mut u8) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_result < __with_a
}
pub unsafe fn __with_builtin_sub_overflow_u8(__with_a: u8, __with_b: u8, __with_out: *mut u8) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_a < __with_b
}
pub unsafe fn __with_builtin_mul_overflow_u8(__with_a: u8, __with_b: u8, __with_out: *mut u8) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_b == 0: false else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_i16(__with_a: i16, __with_b: i16, __with_out: *mut i16) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_result ^ __with_a) & (__with_result ^ __with_b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i16(__with_a: i16, __with_b: i16, __with_out: *mut i16) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_a ^ __with_b) & (__with_result ^ __with_a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i16(__with_a: i16, __with_b: i16, __with_out: *mut i16) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_a == 0 or __with_b == 0: false else if __with_a == -1: __with_result == __with_b else if __with_b == -1: __with_result == __with_a else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_u16(__with_a: u16, __with_b: u16, __with_out: *mut u16) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_result < __with_a
}
pub unsafe fn __with_builtin_sub_overflow_u16(__with_a: u16, __with_b: u16, __with_out: *mut u16) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_a < __with_b
}
pub unsafe fn __with_builtin_mul_overflow_u16(__with_a: u16, __with_b: u16, __with_out: *mut u16) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_b == 0: false else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_i32(__with_a: i32, __with_b: i32, __with_out: *mut i32) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_result ^ __with_a) & (__with_result ^ __with_b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i32(__with_a: i32, __with_b: i32, __with_out: *mut i32) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_a ^ __with_b) & (__with_result ^ __with_a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i32(__with_a: i32, __with_b: i32, __with_out: *mut i32) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_a == 0 or __with_b == 0: false else if __with_a == -1: __with_result == __with_b else if __with_b == -1: __with_result == __with_a else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_u32(__with_a: u32, __with_b: u32, __with_out: *mut u32) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_result < __with_a
}
pub unsafe fn __with_builtin_sub_overflow_u32(__with_a: u32, __with_b: u32, __with_out: *mut u32) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_a < __with_b
}
pub unsafe fn __with_builtin_mul_overflow_u32(__with_a: u32, __with_b: u32, __with_out: *mut u32) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_b == 0: false else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_i64(__with_a: i64, __with_b: i64, __with_out: *mut i64) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_result ^ __with_a) & (__with_result ^ __with_b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i64(__with_a: i64, __with_b: i64, __with_out: *mut i64) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_a ^ __with_b) & (__with_result ^ __with_a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i64(__with_a: i64, __with_b: i64, __with_out: *mut i64) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_a == 0 or __with_b == 0: false else if __with_a == -1: __with_result == __with_b else if __with_b == -1: __with_result == __with_a else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_u64(__with_a: u64, __with_b: u64, __with_out: *mut u64) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_result < __with_a
}
pub unsafe fn __with_builtin_sub_overflow_u64(__with_a: u64, __with_b: u64, __with_out: *mut u64) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_a < __with_b
}
pub unsafe fn __with_builtin_mul_overflow_u64(__with_a: u64, __with_b: u64, __with_out: *mut u64) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_b == 0: false else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_i128(__with_a: i128, __with_b: i128, __with_out: *mut i128) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_result ^ __with_a) & (__with_result ^ __with_b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i128(__with_a: i128, __with_b: i128, __with_out: *mut i128) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_a ^ __with_b) & (__with_result ^ __with_a)) < 0
}
// The 128-bit overflow checks stay division-free on purpose: `/` on i128/u128
// lowers to the __divti3/__udivti3 compiler-rt libcalls, and this shim is
// compiled into freestanding runtime objects whose COFF link has no builtins
// library to resolve them from. Limb decomposition keeps the check to multiplies
// and shifts, which lower inline on every target and at every -O level.
pub fn u128_mul_would_overflow(__with_a: u128, __with_b: u128) -> bool {
    let __with_a_hi = (__with_a >> 64) as u64
    let __with_b_hi = (__with_b >> 64) as u64
    if __with_a_hi != 0 and __with_b_hi != 0: return true
    let __with_a_lo = (__with_a as u64) as u128
    let __with_b_lo = (__with_b as u64) as u128
    let __with_cross = (__with_a_hi as u128) *% __with_b_lo +% (__with_b_hi as u128) *% __with_a_lo
    if (__with_cross >> 64) != 0: return true
    let __with_low = __with_a_lo *% __with_b_lo
    ((__with_low >> 64) +% __with_cross) >> 64 != 0
}
pub unsafe fn __with_builtin_mul_overflow_i128(__with_a: i128, __with_b: i128, __with_out: *mut i128) -> bool {
    unsafe { (*__with_out = __with_a *% __with_b) }
    if __with_a == 0 or __with_b == 0: return false
    let __with_neg = (__with_a < 0) != (__with_b < 0)
    let __with_ua = if __with_a < 0: (0 as u128) -% (__with_a as u128) else: __with_a as u128
    let __with_ub = if __with_b < 0: (0 as u128) -% (__with_b as u128) else: __with_b as u128
    if u128_mul_would_overflow(__with_ua, __with_ub): return true
    let __with_limit = if __with_neg: (1 as u128) << 127 else: ((1 as u128) << 127) -% 1
    __with_ua *% __with_ub > __with_limit
}
pub unsafe fn __with_builtin_add_overflow_u128(__with_a: u128, __with_b: u128, __with_out: *mut u128) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_result < __with_a
}
pub unsafe fn __with_builtin_sub_overflow_u128(__with_a: u128, __with_b: u128, __with_out: *mut u128) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_a < __with_b
}
pub unsafe fn __with_builtin_mul_overflow_u128(__with_a: u128, __with_b: u128, __with_out: *mut u128) -> bool {
    unsafe { (*__with_out = __with_a *% __with_b) }
    u128_mul_would_overflow(__with_a, __with_b)
}
pub extern fn with_clz(x: i32) -> i32
pub extern fn with_ctz(x: i32) -> i32
pub extern fn with_popcount(x: i32) -> i32
pub extern fn with_bswap16(x: u16) -> u16
pub extern fn with_bswap32(x: u32) -> u32
pub extern fn with_bswap64(x: u64) -> u64
pub extern fn with_clzl(x: i64) -> i32
pub extern fn with_clzll(x: i64) -> i32
pub extern fn with_ctzl(x: i64) -> i32
pub extern fn with_ctzll(x: i64) -> i32
pub extern fn with_abs(x: i32) -> i32
pub extern fn with_alloc(size: i64) -> *mut u8
pub extern fn with_alloc_zeroed(count: i64, size: i64) -> *mut u8
pub extern fn with_realloc(ptr: *mut u8, old_size: i64, new_size: i64) -> *mut u8
pub extern fn with_free(ptr: *mut u8)
pub extern fn with_memcpy(dst: *mut u8, src: *const u8, n: i64) -> *mut u8
pub extern fn with_memmove(dst: *mut u8, src: *const u8, n: i64) -> *mut u8
pub extern fn with_memset(dst: *mut u8, c: i32, n: i64) -> *mut u8
pub extern fn with_memcmp(a: *const u8, b: *const u8, n: i64) -> i32


pub type BlockHeader = _BlockHeader

pub type _BlockHeader { magic_number: c_uint = 0, bytes: c_ulong = 0 }
impl Copy for _BlockHeader

pub var allocation_limit: c_int = -1

pub type ArrayListValue = *mut c_void

pub type ArrayList = _ArrayList

pub type _ArrayList { data: *mut *mut c_void = null, length: c_uint = 0, _alloced: c_uint = 0 }
impl Copy for _ArrayList

pub type ArrayListEqualFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type ArrayListCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type AVLTree = _AVLTree

pub type AVLTreeKey = *mut c_void

pub type AVLTreeValue = *mut c_void

pub type AVLTreeNode = _AVLTreeNode

pub type AVLTreeNodeSide = c_uint

pub let AVL_TREE_NODE_LEFT: c_int = 0
pub let AVL_TREE_NODE_RIGHT: c_int = 1
pub type AVLTreeCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type _AVLTreeNode { children: [2]*mut _AVLTreeNode = [null as *mut _AVLTreeNode; 2], parent: *mut _AVLTreeNode = null, key: *mut c_void = null, value: *mut c_void = null, height: c_int = 0 }
impl Copy for _AVLTreeNode

pub type _AVLTree { root_node: *mut _AVLTreeNode = null, compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, num_nodes: c_uint = 0 }
impl Copy for _AVLTree

pub type BinaryHeapType = c_uint

pub let BINARY_HEAP_TYPE_MIN: c_int = 0
pub let BINARY_HEAP_TYPE_MAX: c_int = 1
pub type BinaryHeapValue = *mut c_void

pub type BinaryHeapCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type BinaryHeap = _BinaryHeap

pub type _BinaryHeap { heap_type: i32 = 0, values: *mut *mut c_void = null, num_values: c_uint = 0, alloced_size: c_uint = 0, compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int }
impl Copy for _BinaryHeap

pub type BinomialHeapType = c_uint

pub let BINOMIAL_HEAP_TYPE_MIN: c_int = 0
pub let BINOMIAL_HEAP_TYPE_MAX: c_int = 1
pub type BinomialHeapValue = *mut c_void

pub type BinomialHeapCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type BinomialHeap = _BinomialHeap

pub type BinomialTree = _BinomialTree

pub type _BinomialTree { value: *mut c_void = null, order: c_ushort = 0, refcount: c_ushort = 0, subtrees: *mut *mut _BinomialTree = null }
impl Copy for _BinomialTree

pub type _BinomialHeap { heap_type: i32 = 0, compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, num_values: c_uint = 0, roots: *mut *mut _BinomialTree = null, roots_length: c_uint = 0 }
impl Copy for _BinomialHeap

pub type BloomFilter = _BloomFilter

pub type BloomFilterValue = *mut c_void

pub type BloomFilterHashFunc = unsafe extern "C" fn(*mut c_void) -> c_uint

pub type _BloomFilter { hash_func: unsafe extern "C" fn(*mut c_void) -> c_uint, table: *mut u8 = null, table_size: c_uint = 0, num_functions: c_uint = 0 }
impl Copy for _BloomFilter

pub type UnitTestFunction = extern "C" fn() -> Unit

pub type HashTable = _HashTable

pub type HashTableIterator = _HashTableIterator

pub type HashTableEntry = _HashTableEntry

pub type HashTableKey = *mut c_void

pub type HashTableValue = *mut c_void

pub type _HashTablePair { key: *mut c_void = null, value: *mut c_void = null }
impl Copy for _HashTablePair

pub type HashTablePair = _HashTablePair

pub type _HashTableIterator { hash_table: *mut _HashTable = null, next_entry: *mut _HashTableEntry = null, next_chain: c_uint = 0 }
impl Copy for _HashTableIterator

pub type HashTableHashFunc = unsafe extern "C" fn(*mut c_void) -> c_uint

pub type HashTableEqualFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type HashTableKeyFreeFunc = unsafe extern "C" fn(*mut c_void) -> Unit

pub type HashTableValueFreeFunc = unsafe extern "C" fn(*mut c_void) -> Unit

pub type _HashTableEntry { pair: _HashTablePair, next: *mut _HashTableEntry = null }
impl Copy for _HashTableEntry

pub type _HashTable { table: *mut *mut _HashTableEntry = null, table_size: c_uint = 0, hash_func: unsafe extern "C" fn(*mut c_void) -> c_uint, equal_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, key_free_func: unsafe extern "C" fn(*mut c_void) -> Unit, value_free_func: unsafe extern "C" fn(*mut c_void) -> Unit, entries: c_uint = 0, prime_index: c_uint = 0 }
impl Copy for _HashTable

pub type ListEntry = _ListEntry

pub type ListIterator = _ListIterator

pub type ListValue = *mut c_void

pub type _ListIterator { prev_next: *mut *mut _ListEntry = null, current: *mut _ListEntry = null }
impl Copy for _ListIterator

pub type ListCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type ListEqualFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type _ListEntry { data: *mut c_void = null, prev: *mut _ListEntry = null, next: *mut _ListEntry = null }
impl Copy for _ListEntry

pub type Queue = _Queue

pub type QueueValue = *mut c_void

pub type QueueEntry = _QueueEntry

pub type _QueueEntry { data: *mut c_void = null, prev: *mut _QueueEntry = null, next: *mut _QueueEntry = null }
impl Copy for _QueueEntry

pub type _Queue { head: *mut _QueueEntry = null, tail: *mut _QueueEntry = null }
impl Copy for _Queue

pub type RBTree = _RBTree

pub type RBTreeKey = *mut c_void

pub type RBTreeValue = *mut c_void

pub type RBTreeNode = _RBTreeNode

pub type RBTreeCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type RBTreeNodeColor = c_uint

pub let RB_TREE_NODE_RED: c_int = 0
pub let RB_TREE_NODE_BLACK: c_int = 1
pub type RBTreeNodeSide = c_uint

pub let RB_TREE_NODE_LEFT: c_int = 0
pub let RB_TREE_NODE_RIGHT: c_int = 1
pub type _RBTreeNode { color: i32 = 0, key: *mut c_void = null, value: *mut c_void = null, parent: *mut _RBTreeNode = null, children: [2]*mut _RBTreeNode = [null as *mut _RBTreeNode; 2] }
impl Copy for _RBTreeNode

pub type _RBTree { root_node: *mut _RBTreeNode = null, compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, num_nodes: c_int = 0 }
impl Copy for _RBTree

pub type Set = _Set

pub type SetIterator = _SetIterator

pub type SetEntry = _SetEntry

pub type SetValue = *mut c_void

pub type _SetIterator { set: *mut _Set = null, next_entry: *mut _SetEntry = null, next_chain: c_uint = 0 }
impl Copy for _SetIterator

pub type SetHashFunc = unsafe extern "C" fn(*mut c_void) -> c_uint

pub type SetEqualFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type SetFreeFunc = unsafe extern "C" fn(*mut c_void) -> Unit

pub type _SetEntry { data: *mut c_void = null, next: *mut _SetEntry = null }
impl Copy for _SetEntry

pub type _Set { table: *mut *mut _SetEntry = null, entries: c_uint = 0, table_size: c_uint = 0, prime_index: c_uint = 0, hash_func: unsafe extern "C" fn(*mut c_void) -> c_uint, equal_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, free_func: unsafe extern "C" fn(*mut c_void) -> Unit }
impl Copy for _Set

pub type SListEntry = _SListEntry

pub type SListIterator = _SListIterator

pub type SListValue = *mut c_void

pub type _SListIterator { prev_next: *mut *mut _SListEntry = null, current: *mut _SListEntry = null }
impl Copy for _SListIterator

pub type SListCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type SListEqualFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type _SListEntry { data: *mut c_void = null, next: *mut _SListEntry = null }
impl Copy for _SListEntry

pub type SortedArrayValue = *mut c_void

pub type SortedArray = _SortedArray

pub type SortedArrayCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type _SortedArray { data: *mut *mut c_void = null, length: c_uint = 0, _alloced: c_uint = 0, cmp_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int }
impl Copy for _SortedArray

pub var value1: c_int = 1

pub var value2: c_int = 2

pub var value3: c_int = 3

pub var value4: c_int = 4

pub var allocated_keys: c_int = 0

pub var allocated_values: c_int = 0

pub type Trie = _Trie

pub type TrieValue = *mut c_void

pub type TrieNode = _TrieNode

pub type _TrieNode { data: *mut c_void = null, use_count: c_uint = 0, next: [256]*mut _TrieNode = [null as *mut _TrieNode; 256] }
impl Copy for _TrieNode

pub type _Trie { root_node: *mut _TrieNode = null }
impl Copy for _Trie
