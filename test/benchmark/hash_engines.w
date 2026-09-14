// Hash engine benchmark (docs/stdlib_sourcing_plan.md, Phase 2 gate): the
// three TommyDS engines and the c-algorithms hash table, each called raw
// with i32 keys, against today's rt_core HashMap and the HashIndex facade,
// under one compilation. Prints nanoseconds per operation (median of three
// rounds) for insert, lookup and remove of n keys.
//
//     with run test/benchmark/hash_engines.w

use std.collections
use std.collections.hash_index.HashIndex
use std.time
use std.builtins
use std.tommyds.defs
use std.tommyds.tommyhash
use std.tommyds.tommyhashdyn
use std.tommyds.tommyhashlin
use std.tommyds.tommyhashtbl
use std.c_algorithms.defs
use std.c_algorithms.hash_table
use std.c_algorithms.hash_int
use std.c_algorithms.compare_int

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

/// An intrusive TommyDS item: the node first, then the key.
type Item { node: tommy_node_struct, key: i32 }

fn item_key_compare(arg: *const c_void, obj: *const c_void) -> c_int:
    if unsafe { *(arg as *const i32) } == unsafe { (*(obj as *const Item)).key }: 0 else: 1

fn key_hash(key: i32) -> c_ulonglong: tommy_inthash_u32(key as c_uint) as c_ulonglong

fn items_new(n: i32) -> *mut Item:
    let items = unsafe { with_alloc(n as i64 * sizeof[Item]() as i64) } as *mut Item
    for i in 0..n:
        unsafe { *(items + i as u64) = Item { node: tommy_node_struct { }, key: i } }
    items

type Timing { insert: i64, lookup: i64, remove: i64 }

fn hashmap_round(n: i32) -> Timing:
    var map = HashMap[i32, i32].new()
    let t0 = now_ns()
    for i in 0..n: map.insert(i, i)
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        if map.get(i).is_some(): hits = hits + 1
    let t2 = now_ns()
    for i in 0..n: assert(map.remove(i).is_some())
    let t3 = now_ns()
    assert(hits == n and map.len() == 0)
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn hash_index_round(n: i32) -> Timing:
    var index = HashIndex[i32, i32].new()
    let t0 = now_ns()
    for i in 0..n: index.insert(i, i)
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        if index.get(&i).is_some(): hits = hits + 1
    let t2 = now_ns()
    for i in 0..n: assert(index.remove(&i).is_some())
    let t3 = now_ns()
    assert(hits == n and index.len() == 0)
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn hashdyn_round(n: i32) -> Timing:
    let items = items_new(n)
    var engine = tommy_hashdyn_struct { }
    unsafe { tommy_hashdyn_init(&raw mut engine) }
    let t0 = now_ns()
    for i in 0..n:
        let item = items + i as u64
        unsafe { tommy_hashdyn_insert(&raw mut engine, &raw mut (*item).node, item as *mut c_void, key_hash(i)) }
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        var key = i
        if unsafe { tommy_hashdyn_search(&raw mut engine, item_key_compare, &raw const key as *const c_void, key_hash(i)) } as i64 != 0: hits = hits + 1
    let t2 = now_ns()
    for i in 0..n:
        var key = i
        assert(unsafe { tommy_hashdyn_remove(&raw mut engine, item_key_compare, &raw const key as *const c_void, key_hash(i)) } as i64 != 0)
    let t3 = now_ns()
    assert(hits == n and engine.count == 0)
    unsafe { tommy_hashdyn_done(&raw mut engine) }
    unsafe { with_free(items as *mut u8) }
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn hashlin_round(n: i32) -> Timing:
    let items = items_new(n)
    var engine = tommy_hashlin_struct { }
    unsafe { tommy_hashlin_init(&raw mut engine) }
    let t0 = now_ns()
    for i in 0..n:
        let item = items + i as u64
        unsafe { tommy_hashlin_insert(&raw mut engine, &raw mut (*item).node, item as *mut c_void, key_hash(i)) }
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        var key = i
        if unsafe { tommy_hashlin_search(&raw mut engine, item_key_compare, &raw const key as *const c_void, key_hash(i)) } as i64 != 0: hits = hits + 1
    let t2 = now_ns()
    for i in 0..n:
        var key = i
        assert(unsafe { tommy_hashlin_remove(&raw mut engine, item_key_compare, &raw const key as *const c_void, key_hash(i)) } as i64 != 0)
    let t3 = now_ns()
    assert(hits == n and engine.count == 0)
    unsafe { tommy_hashlin_done(&raw mut engine) }
    unsafe { with_free(items as *mut u8) }
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn hashtable_round(n: i32) -> Timing:
    let items = items_new(n)
    var engine = tommy_hashtable_struct { }
    unsafe { tommy_hashtable_init(&raw mut engine, n as c_ulonglong) }
    let t0 = now_ns()
    for i in 0..n:
        let item = items + i as u64
        unsafe { tommy_hashtable_insert(&raw mut engine, &raw mut (*item).node, item as *mut c_void, key_hash(i)) }
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        var key = i
        if unsafe { tommy_hashtable_search(&raw mut engine, item_key_compare, &raw const key as *const c_void, key_hash(i)) } as i64 != 0: hits = hits + 1
    let t2 = now_ns()
    for i in 0..n:
        var key = i
        assert(unsafe { tommy_hashtable_remove(&raw mut engine, item_key_compare, &raw const key as *const c_void, key_hash(i)) } as i64 != 0)
    let t3 = now_ns()
    assert(hits == n and engine.count == 0)
    unsafe { tommy_hashtable_done(&raw mut engine) }
    unsafe { with_free(items as *mut u8) }
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn calg_round(n: i32) -> Timing:
    // The c-algorithms table hashes and compares through key pointers.
    let keys = unsafe { with_alloc(n as i64 * 4) } as *mut i32
    for i in 0..n: unsafe { *(keys + i as u64) = i }
    let table = hash_table_new(int_hash, int_equal)
    let t0 = now_ns()
    for i in 0..n:
        let key = (keys + i as u64) as *mut c_void
        assert(unsafe { hash_table_insert(table, key, key) } != 0)
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        if unsafe { hash_table_lookup(table, (keys + i as u64) as *mut c_void) } as i64 != 0: hits = hits + 1
    let t2 = now_ns()
    for i in 0..n:
        assert(unsafe { hash_table_remove(table, (keys + i as u64) as *mut c_void) } != 0)
    let t3 = now_ns()
    assert(hits == n and unsafe { hash_table_num_entries(table) } == 0)
    unsafe { hash_table_free(table) }
    unsafe { with_free(keys as *mut u8) }
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn median(a: i64, b: i64, c: i64) -> i64:
    if a < b:
        if b < c: b else if a < c: c else: a
    else:
        if a < c: a else if b < c: c else: b

fn report(name: &str, round: fn(i32) -> Timing, n: i32):
    let a = round(n)
    let b = round(n)
    let c = round(n)
    let insert = median(a.insert, b.insert, c.insert) / n
    let lookup = median(a.lookup, b.lookup, c.lookup) / n
    let remove = median(a.remove, b.remove, c.remove) / n
    print(f"{name}\t{insert}\t{lookup}\t{remove}")

let n = 200000
print(f"engine\tinsert_ns\tlookup_ns\tremove_ns\t(n={n}, i32 keys, median of 3)")
report("rt_core HashMap", hashmap_round, n)
report("HashIndex (hashdyn)", hash_index_round, n)
report("tommy_hashdyn raw", hashdyn_round, n)
report("tommy_hashlin raw", hashlin_round, n)
report("tommy_hashtable raw", hashtable_round, n)
report("c-algorithms hash_table raw", calg_round, n)
