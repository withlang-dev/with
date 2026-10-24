// std.engines.c_algorithms_testing.defs — shared definitions for migrated PCRE2
use std.option
use rt.rt_core

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
pub extern fn strlen(s: *const c_char) -> u64
pub extern fn strcmp(a: *const c_char, b: *const c_char) -> i32
pub extern fn strncmp(a: *const c_char, b: *const c_char, n: i64) -> i32
pub extern fn strchr(s: *const c_char, c: i32) -> *mut c_char
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

// data model: LP64 (arm64-apple-macosx11.0)
pub const C_DATA_MODEL: str = "LP64 (arm64-apple-macosx11.0)"
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

pub type BlockHeader = _BlockHeader

@[repr(C)]
pub type _BlockHeader { pub magic_number: u32 = 0, pub bytes: u64 = 0 }
impl Copy for _BlockHeader

pub var allocation_limit: i32 = -1

pub let ALLOC_TEST_MAGIC: i32 = 0x72ec82d2
pub let MALLOC_PATTERN: u32 = 0xBAADF00D
pub let FREE_PATTERN: u32 = 0xDEADBEEF
pub type ArrayListValue = *mut c_void

pub type ArrayList = _ArrayList

@[repr(C)]
pub type _ArrayList { pub data: *mut *mut c_void = null, pub length: u32 = 0, pub _alloced: u32 = 0 }
impl Copy for _ArrayList

pub type ArrayListEqualFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32

pub type ArrayListCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32

pub type AVLTree = _AVLTree

pub type AVLTreeKey = *mut c_void

pub type AVLTreeValue = *mut c_void

pub type AVLTreeNode = _AVLTreeNode

pub type AVLTreeNodeSide = i32

pub let AVL_TREE_NODE_LEFT: i32 = 0
pub let AVL_TREE_NODE_RIGHT: i32 = 1
pub type AVLTreeCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32

@[repr(C)]
pub type _AVLTreeNode { pub children: [*mut _AVLTreeNode; 2] = [null as *mut _AVLTreeNode; 2], pub parent: *mut _AVLTreeNode = null, pub key: *mut c_void = null, pub value: *mut c_void = null, pub height: i32 = 0 }
impl Copy for _AVLTreeNode

@[repr(C)]
pub type _AVLTree { pub root_node: *mut _AVLTreeNode = null, pub compare_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32] = null, pub num_nodes: u32 = 0 }
impl Copy for _AVLTree

pub let AVL_TREE_NULL: *mut c_void = null
pub type BinaryHeapType = i32

pub let BINARY_HEAP_TYPE_MIN: i32 = 0
pub let BINARY_HEAP_TYPE_MAX: i32 = 1
pub type BinaryHeapValue = *mut c_void

pub type BinaryHeapCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32

pub type BinaryHeap = _BinaryHeap

@[repr(C)]
pub type _BinaryHeap { pub heap_type: i32 = 0, pub values: *mut *mut c_void = null, pub num_values: u32 = 0, pub alloced_size: u32 = 0, pub compare_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32] = null }
impl Copy for _BinaryHeap

pub let BINARY_HEAP_NULL: *mut c_void = null
pub type BinomialHeapType = i32

pub let BINOMIAL_HEAP_TYPE_MIN: i32 = 0
pub let BINOMIAL_HEAP_TYPE_MAX: i32 = 1
pub type BinomialHeapValue = *mut c_void

pub type BinomialHeapCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32

pub type BinomialHeap = _BinomialHeap

pub type BinomialTree = _BinomialTree

@[repr(C)]
pub type _BinomialTree { pub value: *mut c_void = null, pub order: u16 = 0, pub refcount: u16 = 0, pub subtrees: *mut *mut _BinomialTree = null }
impl Copy for _BinomialTree

@[repr(C)]
pub type _BinomialHeap { pub heap_type: i32 = 0, pub compare_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32] = null, pub num_values: u32 = 0, pub roots: *mut *mut _BinomialTree = null, pub roots_length: u32 = 0 }
impl Copy for _BinomialHeap

pub let BINOMIAL_HEAP_NULL: *mut c_void = null
pub type BloomFilter = _BloomFilter

pub type BloomFilterValue = *mut c_void

pub type BloomFilterHashFunc = unsafe extern "C" fn(*mut c_void) -> u32

@[repr(C)]
pub type _BloomFilter { pub hash_func: Option[unsafe extern "C" fn(*mut c_void) -> u32] = null, pub table: *mut u8 = null, pub table_size: u32 = 0, pub num_functions: u32 = 0 }
impl Copy for _BloomFilter

pub type UnitTestFunction = extern "C" fn() -> Unit

pub type HashTable = _HashTable

pub type HashTableIterator = _HashTableIterator

pub type HashTableEntry = _HashTableEntry

pub type HashTableKey = *mut c_void

pub type HashTableValue = *mut c_void

@[repr(C)]
pub type _HashTablePair { pub key: *mut c_void = null, pub value: *mut c_void = null }
impl Copy for _HashTablePair

pub type HashTablePair = _HashTablePair

@[repr(C)]
pub type _HashTableIterator { pub hash_table: *mut _HashTable = null, pub next_entry: *mut _HashTableEntry = null, pub next_chain: u32 = 0 }
impl Copy for _HashTableIterator

pub type HashTableHashFunc = unsafe extern "C" fn(*mut c_void) -> u32

pub type HashTableEqualFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32

pub type HashTableKeyFreeFunc = unsafe extern "C" fn(*mut c_void) -> Unit

pub type HashTableValueFreeFunc = unsafe extern "C" fn(*mut c_void) -> Unit

@[repr(C)]
pub type _HashTableEntry { pub pair: _HashTablePair, pub next: *mut _HashTableEntry = null }
impl Copy for _HashTableEntry

@[repr(C)]
pub type _HashTable { pub table: *mut *mut _HashTableEntry = null, pub table_size: u32 = 0, pub hash_func: Option[unsafe extern "C" fn(*mut c_void) -> u32] = null, pub equal_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32] = null, pub key_free_func: Option[unsafe extern "C" fn(*mut c_void) -> Unit] = null, pub value_free_func: Option[unsafe extern "C" fn(*mut c_void) -> Unit] = null, pub entries: u32 = 0, pub prime_index: u32 = 0 }
impl Copy for _HashTable

pub let HASH_TABLE_KEY_NULL: *mut c_void = null
pub let HASH_TABLE_NULL: *mut c_void = null
pub type ListEntry = _ListEntry

pub type ListIterator = _ListIterator

pub type ListValue = *mut c_void

@[repr(C)]
pub type _ListIterator { pub prev_next: *mut *mut _ListEntry = null, pub current: *mut _ListEntry = null }
impl Copy for _ListIterator

pub type ListCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32

pub type ListEqualFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32

@[repr(C)]
pub type _ListEntry { pub data: *mut c_void = null, pub prev: *mut _ListEntry = null, pub next: *mut _ListEntry = null }
impl Copy for _ListEntry

pub let LIST_NULL: *mut c_void = null
pub type Queue = _Queue

pub type QueueValue = *mut c_void

pub type QueueEntry = _QueueEntry

@[repr(C)]
pub type _QueueEntry { pub data: *mut c_void = null, pub prev: *mut _QueueEntry = null, pub next: *mut _QueueEntry = null }
impl Copy for _QueueEntry

@[repr(C)]
pub type _Queue { pub head: *mut _QueueEntry = null, pub tail: *mut _QueueEntry = null }
impl Copy for _Queue

pub let QUEUE_NULL: *mut c_void = null
pub type RBTree = _RBTree

pub type RBTreeKey = *mut c_void

pub type RBTreeValue = *mut c_void

pub type RBTreeNode = _RBTreeNode

pub type RBTreeCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32

pub type RBTreeNodeColor = i32

pub let RB_TREE_NODE_RED: i32 = 0
pub let RB_TREE_NODE_BLACK: i32 = 1
pub type RBTreeNodeSide = i32

pub let RB_TREE_NODE_LEFT: i32 = 0
pub let RB_TREE_NODE_RIGHT: i32 = 1
@[repr(C)]
pub type _RBTreeNode { pub color: i32 = 0, pub key: *mut c_void = null, pub value: *mut c_void = null, pub parent: *mut _RBTreeNode = null, pub children: [*mut _RBTreeNode; 2] = [null as *mut _RBTreeNode; 2] }
impl Copy for _RBTreeNode

@[repr(C)]
pub type _RBTree { pub root_node: *mut _RBTreeNode = null, pub compare_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32] = null, pub num_nodes: i32 = 0 }
impl Copy for _RBTree

pub let RB_TREE_NULL: *mut c_void = null
pub type Set = _Set

pub type SetIterator = _SetIterator

pub type SetEntry = _SetEntry

pub type SetValue = *mut c_void

@[repr(C)]
pub type _SetIterator { pub set: *mut _Set = null, pub next_entry: *mut _SetEntry = null, pub next_chain: u32 = 0 }
impl Copy for _SetIterator

pub type SetHashFunc = unsafe extern "C" fn(*mut c_void) -> u32

pub type SetEqualFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32

pub type SetFreeFunc = unsafe extern "C" fn(*mut c_void) -> Unit

@[repr(C)]
pub type _SetEntry { pub data: *mut c_void = null, pub next: *mut _SetEntry = null }
impl Copy for _SetEntry

@[repr(C)]
pub type _Set { pub table: *mut *mut _SetEntry = null, pub entries: u32 = 0, pub table_size: u32 = 0, pub prime_index: u32 = 0, pub hash_func: Option[unsafe extern "C" fn(*mut c_void) -> u32] = null, pub equal_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32] = null, pub free_func: Option[unsafe extern "C" fn(*mut c_void) -> Unit] = null }
impl Copy for _Set

pub let SET_NULL: *mut c_void = null
pub type SListEntry = _SListEntry

pub type SListIterator = _SListIterator

pub type SListValue = *mut c_void

@[repr(C)]
pub type _SListIterator { pub prev_next: *mut *mut _SListEntry = null, pub current: *mut _SListEntry = null }
impl Copy for _SListIterator

pub type SListCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32

pub type SListEqualFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32

@[repr(C)]
pub type _SListEntry { pub data: *mut c_void = null, pub next: *mut _SListEntry = null }
impl Copy for _SListEntry

pub let SLIST_NULL: *mut c_void = null
pub type SortedArrayValue = *mut c_void

pub type SortedArray = _SortedArray

pub type SortedArrayCompareFunc = unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32

@[repr(C)]
pub type _SortedArray { pub data: *mut *mut c_void = null, pub length: u32 = 0, pub _alloced: u32 = 0, pub cmp_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32] = null }
impl Copy for _SortedArray

pub let SORTED_ARRAY_NULL: *mut c_void = null
pub let NUM_TEST_VALUES: u64 = 100
pub let REMOVE_IDX_1: i32 = 23
pub let REMOVE_IDX_2: i32 = 57
pub let REMOVE_IDX_2_LEN: i32 = 7
pub let REMOVE_IDX_3: i32 = 95
pub let REMOVE_IDX_3_LEN: i32 = 10
pub let REMOVE_IDX_3_REAL_LEN: i32 = 5
pub type Trie = _Trie

pub type TrieValue = *mut c_void

pub type TrieNode = _TrieNode

@[repr(C)]
pub type _TrieNode { pub data: *mut c_void = null, pub use_count: u32 = 0, pub next: [*mut _TrieNode; 256] = [null as *mut _TrieNode; 256] }
impl Copy for _TrieNode

@[repr(C)]
pub type _Trie { pub root_node: *mut _TrieNode = null }
impl Copy for _Trie

pub let TRIE_NULL: *mut c_void = null
