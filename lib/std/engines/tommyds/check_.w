// Migrated from C
use std.engines.tommyds.defs
use std.engines.tommyds.tommyhash
use std.engines.tommyds.tommyalloc
use std.engines.tommyds.tommyarray
use std.engines.tommyds.tommyarrayof
use std.engines.tommyds.tommyarrayblk
use std.engines.tommyds.tommyarrayblkof
use std.engines.tommyds.tommylist
use std.engines.tommyds.tommytree
use std.engines.tommyds.tommytrie
use std.engines.tommyds.tommytrieinp
use std.engines.tommyds.tommyhashtbl
use std.engines.tommyds.tommyhashdyn
use std.engines.tommyds.tommyhashlin
use std.libc
use std.option
use std.collections

fn tommy_ilog2_u32(__param_value: u32) -> u32 {
    return (((((__param_value as u32).clz() as i32) ^ (31 as i32)) as u32))

}

fn tommy_ilog2_u64(__param_value: u64) -> u32 {
    return (((((__param_value as u64).clz() as i32) ^ (63 as i32)) as u32))

}

fn tommy_ctz_u32(__param_value: u32) -> u32 {
    return (((__param_value as u32).ctz() as u32))

}

fn tommy_ctz_u64(__param_value: u64) -> u32 {
    return (((__param_value as u64).ctz() as u32))

}

fn tommy_roundup_pow2_u32(__param_value: u32) -> u32 {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (1 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (2 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (4 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (8 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (16 as u32)) as u32))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_roundup_pow2_u64(__param_value: u64) -> u64 {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (1 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (2 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (4 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (8 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (16 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (32 as u32)) as u64))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_haszero_u32(__param_value: u32) -> i32 {
    return (if ((((((__param_value as u32) -% (16843009 as u32)) as u32) & ((~__param_value) as u32)) as u32) & (2155905152 as u32)) != 0: 1 else: 0)

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn compare(__param_void_a: *const c_void, __param_void_b: *const c_void) -> i32 writes compare_counter {
    var __local_a: *const object = ((__param_void_a as *const object))

    var __local_b: *const object = ((__param_void_b as *const object))

    (compare_counter = (compare_counter +% 1))

    if ((*__local_a).value < (*__local_b).value) {
        return -1
    }

    if ((*__local_a).value > (*__local_b).value) {
        return 1
    }

    return 0

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn compare_vector(__param_void_a: *const c_void, __param_void_b: *const c_void) -> i32 writes compare_counter {
    var __local_a: *const object_vector = ((__param_void_a as *const object_vector))

    var __local_b: *const object_vector = ((__param_void_b as *const object_vector))

    (compare_counter = (compare_counter +% 1))

    if ((*__local_a).value < (*__local_b).value) {
        return -1
    }

    if ((*__local_a).value > (*__local_b).value) {
        return 1
    }

    return 0

}

fn nano_init() {
    return
}

fn nano() -> u64 {
    var __local_ret: u64

    var __local_info: mach_timebase_info

    var __local_r: i32

    var __local_t: u64

    (__local_t = mach_absolute_time())

    (__local_r = ((unsafe { mach_timebase_info((&raw mut __local_info as *mut mach_timebase_info)) } as i32)))

    if (__local_r != 0) {
        abort()
    }

    (__local_ret = ((((((__local_t as u64) / ((unsafe *(&raw const __local_info as *const mach_timebase_info)).denom as u64)) as u64) *% ((unsafe *(&raw const __local_info as *const mach_timebase_info)).numer as u64)) as u64)))

    (__local_ret = (__local_ret +% ((((((__local_t as u64) % ((unsafe *(&raw const __local_info as *const mach_timebase_info)).denom as u64)) as u64) *% ((unsafe *(&raw const __local_info as *const mach_timebase_info)).numer as u64)) as u64) / ((unsafe *(&raw const __local_info as *const mach_timebase_info)).denom as u64))))

    return __local_ret

}

pub fn rnd(__param_max: u32) -> u32 writes SEED {
    var __local_r__goto_208_11: u32 = 0

    var __local_divider__goto_209_17: u64 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        (__local_divider__goto_209_17 = ((((((0 as u64) -% 1) as u64) / (__param_max as u64)) as u64)))
        (SEED = ((((((SEED as u64) *% (6364136223846793005 as u64)) as u64) +% (1442695040888963407 as u64)) as u64)))
        (__local_r__goto_208_11 = ((((SEED as u64) / (__local_divider__goto_209_17 as u64)) as u32)))
        if (__local_r__goto_208_11 >= __param_max) {
            goto '__ci_bb_2
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_2 {
        goto '__ci_bb_1
    }

    '__ci_bb_3 {
        return __local_r__goto_208_11
    }

    __ci_unreachable()

}

pub fn isqrt(__param_n: u32) -> u32 {
    var __local_root: u32

    var __local_remain: u32

    var __local_place: u32


    (__local_root = ((0 as u32)))

    (__local_remain = __param_n)

    (__local_place = ((1073741824 as u32)))

    while (__local_place > __local_remain) {
        (__local_place = __local_place / 4)
    }

    while __local_place {
        if (__local_remain >= ((__local_root as u32) +% (__local_place as u32))) {
            (__local_remain = (__local_remain -% ((__local_root as u32) +% (__local_place as u32))))

            (__local_root = (__local_root +% ((2 as u32) *% (__local_place as u32))))

        }

        (__local_root = __local_root / 2)

        (__local_place = __local_place / 4)

    }

    return __local_root

}

pub fn cache_clear() {
    var __local_i: u32

    (__local_i = ((0 as u32)))

    while (__local_i < (16777216 * (sizeof[u8]() as usize))) {
        (the_cache[__local_i] = ((((the_cache[__local_i] as i32) +% 1) as u8)))

        (__local_i = (__local_i +% 32))

    }


}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn start(__param_str: *const c_char) writes compare_counter {
    cache_clear()

    (compare_counter = ((0 as u32)))

    (the_str = __param_str)

    (the_start = ((nano() as u64)))

}

pub fn stop() -> Unit {
    var __local_the_stop: u64 = ((nano() as u64))

    printf(c"%25s %8u [ms], %8u [compare]\n".ptr, the_str, (((((__local_the_stop as u64) -% (the_start as u64)) as u64) / (1000000 as u64)) as u32), compare_counter)

}

// contract: unproved:0:read only
unsafe fn count_callback(__param_data: *mut c_void) {

    (the_count = (the_count +% 1))

}

// contract: unproved:0:out-parameter read before the write,unproved:1:read only
unsafe fn count_arg_callback(__param_arg: *mut c_void, __param_data: *mut c_void) {
    var __local_count: *mut u32 = ((__param_arg as *mut u32))


    ((*__local_count) = ((*__local_count) +% 1))

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn search_callback(__param_arg: *const c_void, __param_obj: *const c_void) -> i32 {
    return (if __param_arg != __param_obj: 1 else: 0)

}

pub fn test_hash() writes compare_counter {
    var __local_i: u32

    var __local_buffer: List[u8] = [0; 16]

    var __local_COUNT: u32 = ((16777216 as u32))

    var __local_hash32: u32

    var __local_hash64: u64

    unsafe { start(c"hash_test_vectors".ptr) }

    (__local_i = ((0 as u32)))

    while (HASH32[__local_i].data != null) {
        if (unsafe { tommy_hash_u32((2808510813 as u32), (HASH32[__local_i].data as *const c_void), (HASH32[__local_i].len as u64)) } != HASH32[__local_i].hash) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (STRHASH32[__local_i].data != null) {
        if (unsafe { tommy_strhash_u32((2808510813 as u32), (STRHASH32[__local_i].data as *const c_void)) } != STRHASH32[__local_i].hash) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (HASH64[__local_i].data != null) {
        if (unsafe { tommy_hash_u64((3387313247419267421 as u64), (HASH64[__local_i].data as *const c_void), (HASH64[__local_i].len as u64)) } != HASH64[__local_i].hash) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while true {
        var __ci_expr_logic_0: i32

        if INTHASH32[__local_i].value {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if not __local_i: 1 else: 0))
        }

        if (not __ci_expr_logic_0) {
            break
        }

        if (tommy_inthash_u32(INTHASH32[__local_i].value) != INTHASH32[__local_i].hash) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while true {
        var __ci_expr_logic_1: i32

        if INTHASH64[__local_i].value {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if not __local_i: 1 else: 0))
        }

        if (not __ci_expr_logic_1) {
            break
        }

        if (tommy_inthash_u64(INTHASH64[__local_i].value) != INTHASH64[__local_i].hash) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    stop()

    with_memset(((&__local_buffer[0] as *mut u8) as *mut u8), (170 as i32), (((16 * (sizeof[u8]() as usize)) as u64) as i64))

    (__local_buffer[(((16 * (sizeof[u8]() as usize)) as u64) -% (1 as u64))] = ((0 as u8)))

    (__local_hash32 = ((0 as u32)))

    (__local_hash64 = ((0 as u64)))

    unsafe { start(c"hash_u32".ptr) }

    (__local_i = ((0 as u32)))

    while (__local_i < __local_COUNT) {
        (__local_hash32 = ((unsafe { tommy_hash_u32(__local_hash32, (&__local_buffer[0] as *mut u8), (16 as u64)) } as u32)))


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"strhash_u32".ptr) }

    (__local_i = ((0 as u32)))

    while (__local_i < __local_COUNT) {
        (__local_hash32 = ((unsafe { tommy_strhash_u32(__local_hash32, (&__local_buffer[0] as *mut u8)) } as u32)))


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"hash_u64".ptr) }

    (__local_i = ((0 as u32)))

    while (__local_i < __local_COUNT) {
        (__local_hash64 = ((unsafe { tommy_hash_u64(__local_hash64, (&__local_buffer[0] as *mut u8), (16 as u64)) } as u64)))


        (__local_i = (__local_i +% 1))

    }


    stop()

}

pub fn test_alloc() writes compare_counter {
    var __local_size: u32 = ((10000000 as u32))

    var __local_i: u32

    var __local_alloc: tommy_allocator_struct

    var __local_PTR: *mut *mut c_void

    (__local_PTR = (((with_alloc(((((10000000 as u64) *% (sizeof[usize]() as u64)) as u64) as i64)) as *mut c_void) as *mut *mut c_void)))

    unsafe { (*(&raw mut __local_alloc as *mut tommy_allocator_struct)).tommy_allocator_init((8 as u64), (1 as u64)) }

    if ((unsafe *(&raw const __local_alloc as *const tommy_allocator_struct)).align_size < 8) {
        abort()
    }

    unsafe { (*(&raw mut __local_alloc as *mut tommy_allocator_struct)).tommy_allocator_done() }

    unsafe { (*(&raw mut __local_alloc as *mut tommy_allocator_struct)).tommy_allocator_init((7 as u64), (8 as u64)) }

    if ((unsafe *(&raw const __local_alloc as *const tommy_allocator_struct)).block_size != 8) {
        abort()
    }

    unsafe { (*(&raw mut __local_alloc as *mut tommy_allocator_struct)).tommy_allocator_done() }

    unsafe { (*(&raw mut __local_alloc as *mut tommy_allocator_struct)).tommy_allocator_init((128000 as u64), (64 as u64)) }

    if (unsafe { (*(&raw mut __local_alloc as *mut tommy_allocator_struct)).tommy_allocator_alloc() } == 0) {
        abort()
    }

    unsafe { (*(&raw mut __local_alloc as *mut tommy_allocator_struct)).tommy_allocator_done() }

    unsafe { (*(&raw mut __local_alloc as *mut tommy_allocator_struct)).tommy_allocator_init((64 as u64), (64 as u64)) }

    unsafe { start(c"alloc".ptr) }

    (__local_i = ((0 as u32)))

    while (__local_i < 10000000) {
        ((unsafe __local_PTR[__local_i]) = unsafe { (*(&raw mut __local_alloc as *mut tommy_allocator_struct)).tommy_allocator_alloc() })


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"free".ptr) }

    (__local_i = ((0 as u32)))

    while (__local_i < 10000000) {
        unsafe { tommy_allocator_free((&raw mut __local_alloc as *mut tommy_allocator_struct), (__local_PTR[__local_i])) }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { (*(&raw mut __local_alloc as *mut tommy_allocator_struct)).tommy_allocator_done() }

    with_free(((__local_PTR as *mut c_void) as *mut u8))

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn test_list_order(__param_list: *mut tommy_node_struct) {
    var __local_node: *mut tommy_node_struct

    (__local_node = __param_list)

    while (__local_node != null) {
        if ((*__local_node).next != null) {
            var __local_a: *const object = (((*__local_node).data as *const object))

            var __local_b: *const object = (((*(*__local_node).next).data as *const object))

            if ((*__local_a).value > (*__local_b).value) {
                abort()
            }

            var __ci_expr_logic_0: i32 = 0

            if ((*__local_a).value == (*__local_b).value) {
                (__ci_expr_logic_0 = (if __local_a > __local_b: 1 else: 0))
            }

            if __ci_expr_logic_0 {
                abort()
            }


        }

        (__local_node = (*__local_node).next)

    }

}

pub fn test_list() writes SEED, compare_counter {
    var __local_LIST: *mut object

    var __local_VECTOR: *mut object_vector

    var __local_list: *mut tommy_node_struct

    var __local_i: u32

    var __local_size: u32 = ((1000000 as u32))

    (__local_LIST = (((with_alloc(((((1000000 as u64) *% (sizeof[object]() as u64)) as u64) as i64)) as *mut c_void) as *mut object)))

    (__local_VECTOR = (((with_alloc(((((1000000 as u64) *% (sizeof[object_vector]() as u64)) as u64) as i64)) as *mut c_void) as *mut object_vector)))

    (__local_i = ((0 as u32)))

    while (__local_i < 1000000) {
        ((unsafe __local_LIST[__local_i]).value = ((0 as i32)))

        ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)



        (__local_i = (__local_i +% 1))

    }


    unsafe { tommy_list_init((&raw mut __local_list as *mut *mut tommy_node_struct)) }

    unsafe { tommy_list_sort((&raw mut __local_list as *mut *mut tommy_node_struct), compare) }

    if (not unsafe { tommy_list_empty((&raw mut __local_list as *mut *mut tommy_node_struct)) }) {
        abort()
    }

    if (unsafe { tommy_list_tail((&raw mut __local_list as *mut *mut tommy_node_struct)) } != 0) {
        abort()
    }

    if (unsafe { tommy_list_head((&raw mut __local_list as *mut *mut tommy_node_struct)) } != 0) {
        abort()
    }

    (__local_i = ((0 as u32)))

    while (__local_i < 1000000) {
        ((unsafe __local_LIST[__local_i]).value = ((rnd((1000000 as u32)) as i32)))

        ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)


        unsafe { tommy_list_insert_tail((&raw mut __local_list as *mut *mut tommy_node_struct), ((&raw const (__local_LIST[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_LIST[__local_i]) as *const object) as *mut object) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    if (unsafe { tommy_list_tail((&raw mut __local_list as *mut *mut tommy_node_struct)) } == 0) {
        abort()
    }

    if (unsafe { tommy_list_head((&raw mut __local_list as *mut *mut tommy_node_struct)) } == 0) {
        abort()
    }

    unsafe { start(c"sort random".ptr) }

    unsafe { tommy_list_sort((&raw mut __local_list as *mut *mut tommy_node_struct), compare) }

    stop()

    unsafe { start(c"C qsort random".ptr) }

    qsort((__local_VECTOR as *mut c_void), (1000000 as u64), (sizeof[object_vector]() as u64), compare_vector)

    stop()

    unsafe { test_list_order(__local_list) }

    (__local_list = null)

    (__local_i = ((0 as u32)))

    while (__local_i < 1000000) {
        ((unsafe __local_LIST[__local_i]).value = ((__local_i as i32)))

        ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)


        if (rnd((100 as u32)) == 0) {
            ((unsafe __local_LIST[__local_i]).value = ((rnd((1000000 as u32)) as i32)))

            ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)

        }

        unsafe { tommy_list_insert_tail((&raw mut __local_list as *mut *mut tommy_node_struct), ((&raw const (__local_LIST[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_LIST[__local_i]) as *const object) as *mut object) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"sort partially ordered".ptr) }

    unsafe { tommy_list_sort((&raw mut __local_list as *mut *mut tommy_node_struct), compare) }

    stop()

    unsafe { start(c"C qsort partially ordered".ptr) }

    qsort((__local_VECTOR as *mut c_void), (1000000 as u64), (sizeof[object_vector]() as u64), compare_vector)

    stop()

    unsafe { test_list_order(__local_list) }

    (__local_list = null)

    (__local_i = ((0 as u32)))

    while (__local_i < 1000000) {
        ((unsafe __local_LIST[__local_i]).value = ((__local_i as i32)))

        ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)


        unsafe { tommy_list_insert_tail((&raw mut __local_list as *mut *mut tommy_node_struct), ((&raw const (__local_LIST[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_LIST[__local_i]) as *const object) as *mut object) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"sort forward".ptr) }

    unsafe { tommy_list_sort((&raw mut __local_list as *mut *mut tommy_node_struct), compare) }

    stop()

    unsafe { start(c"C qsort forward".ptr) }

    qsort((__local_VECTOR as *mut c_void), (1000000 as u64), (sizeof[object_vector]() as u64), compare_vector)

    stop()

    unsafe { test_list_order(__local_list) }

    (__local_list = null)

    (__local_i = ((0 as u32)))

    while (__local_i < 1000000) {
        ((unsafe __local_LIST[__local_i]).value = ((((((1000000 as u32) -% (1 as u32)) as u32) -% (__local_i as u32)) as i32)))

        ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)


        unsafe { tommy_list_insert_tail((&raw mut __local_list as *mut *mut tommy_node_struct), ((&raw const (__local_LIST[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_LIST[__local_i]) as *const object) as *mut object) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"sort backward".ptr) }

    unsafe { tommy_list_sort((&raw mut __local_list as *mut *mut tommy_node_struct), compare) }

    stop()

    unsafe { start(c"C qsort backward".ptr) }

    qsort((__local_VECTOR as *mut c_void), (1000000 as u64), (sizeof[object_vector]() as u64), compare_vector)

    stop()

    unsafe { test_list_order(__local_list) }

    (__local_list = null)

    (__local_i = ((0 as u32)))

    while (__local_i < 1000000) {
        ((unsafe __local_LIST[__local_i]).value = ((rnd((((((1000000 as u32) / (1000 as u32)) as u32) +% (2 as u32)) as u32)) as i32)))

        ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)


        unsafe { tommy_list_insert_tail((&raw mut __local_list as *mut *mut tommy_node_struct), ((&raw const (__local_LIST[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_LIST[__local_i]) as *const object) as *mut object) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"sort random duplicate".ptr) }

    unsafe { tommy_list_sort((&raw mut __local_list as *mut *mut tommy_node_struct), compare) }

    stop()

    unsafe { start(c"C qsort random duplicate".ptr) }

    qsort((__local_VECTOR as *mut c_void), (1000000 as u64), (sizeof[object_vector]() as u64), compare_vector)

    stop()

    unsafe { test_list_order(__local_list) }

    with_free(((__local_LIST as *mut c_void) as *mut u8))

    with_free(((__local_VECTOR as *mut c_void) as *mut u8))

}

pub fn test_tree() writes compare_counter {
    var __local_tree: tommy_tree_struct

    var __local_OBJ: *mut object_tree

    var __local_i: u32

    var __local_size: u32 = ((250000 as u32))

    (__local_OBJ = (((with_alloc(((((250000 as u64) *% (sizeof[object_tree]() as u64)) as u64) as i64)) as *mut c_void) as *mut object_tree)))

    unsafe { start(c"tree".ptr) }

    unsafe { (*(&raw mut __local_tree as *mut tommy_tree_struct)).tommy_tree_init(Some(compare)) }

    (__local_i = ((0 as u32)))

    while (__local_i < 250000) {
        ((unsafe __local_OBJ[__local_i]).value = ((__local_i as i32)))

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < 250000) {
        if (unsafe { tommy_tree_insert((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (__local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } != (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree))) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    if (unsafe { (*(&raw mut __local_tree as *mut tommy_tree_struct)).tommy_tree_memory_usage() } < 8000000) {
        abort()
    }

    if (unsafe { (*(&raw mut __local_tree as *mut tommy_tree_struct)).tommy_tree_count() } != 250000) {
        abort()
    }

    (the_count = ((0 as u32)))

    unsafe { tommy_tree_foreach((&raw mut __local_tree as *mut tommy_tree_struct), count_callback) }

    if (the_count != 250000) {
        abort()
    }

    (the_count = ((0 as u32)))

    unsafe { tommy_tree_foreach_arg((&raw mut __local_tree as *mut tommy_tree_struct), count_arg_callback, ((&raw mut the_count as *mut u32) as *mut c_void)) }

    if (the_count != 250000) {
        abort()
    }

    (__local_i = ((0 as u32)))

    while (__local_i < ((250000 as u32) / (2 as u32))) {
        if (unsafe { tommy_tree_search((&raw mut __local_tree as *mut tommy_tree_struct), (((&raw const (__local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } == 0) {
            abort()
        }

        if (unsafe { tommy_tree_search_compare((&raw mut __local_tree as *mut tommy_tree_struct), compare, (((&raw const (__local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } == 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < 250000) {
        var __local_EXTRA: object_tree

        (__local_EXTRA.value = ((__local_i as i32)))

        if (unsafe { tommy_tree_insert((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (*(&raw const __local_EXTRA as *const object_tree)).node as *const tommy_node_struct) as *mut tommy_node_struct), ((&raw mut __local_EXTRA as *mut object_tree) as *mut c_void)) } == ((&raw mut __local_EXTRA as *mut object_tree))) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < ((250000 as u32) / (2 as u32))) {
        unsafe { tommy_tree_remove_existing((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (__local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < ((250000 as u32) / (2 as u32))) {
        if (unsafe { tommy_tree_remove((&raw mut __local_tree as *mut tommy_tree_struct), (((&raw const (__local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < ((250000 as u32) / (2 as u32))) {
        if (unsafe { tommy_tree_search((&raw mut __local_tree as *mut tommy_tree_struct), (((&raw const (__local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } != 0) {
            abort()
        }

        if (unsafe { tommy_tree_search_compare((&raw mut __local_tree as *mut tommy_tree_struct), compare, (((&raw const (__local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < ((250000 as u32) / (2 as u32))) {
        if (unsafe { tommy_tree_remove((&raw mut __local_tree as *mut tommy_tree_struct), (((&raw const (__local_OBJ[((((250000 as u32) / (2 as u32)) as u32) +% (__local_i as u32))]) as *const object_tree) as *mut object_tree) as *mut c_void)) } == 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < 250000) {
        ((unsafe __local_OBJ[__local_i]).value = ((((250000 as u32) -% (__local_i as u32)) as i32)))

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < 250000) {
        if (unsafe { tommy_tree_insert((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (__local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } != (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree))) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < 250000) {
        unsafe { tommy_tree_remove_existing((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (__local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < 250000) {
        ((unsafe __local_OBJ[__local_i]).value = ((tommy_inthash_u32(__local_i) as i32)))

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < 250000) {
        if (unsafe { tommy_tree_insert((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (__local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } != (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree))) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < 250000) {
        unsafe { tommy_tree_remove_existing((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (__local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

        (__local_i = (__local_i +% 1))

    }


    stop()

}

pub fn test_array() writes compare_counter {
    var __local_array: tommy_array_struct

    var __local_i: u64

    var __local_size: u32 = ((50000000 as u32))

    unsafe { (*(&raw mut __local_array as *mut tommy_array_struct)).tommy_array_init() }

    unsafe { (*(&raw mut __local_array as *mut tommy_array_struct)).tommy_array_grow((0 as u64)) }

    unsafe { start(c"array init".ptr) }

    (__local_i = ((0 as u64)))

    while (__local_i < 50000000) {
        unsafe { (*(&raw mut __local_array as *mut tommy_array_struct)).tommy_array_grow((((__local_i as u64) +% (1 as u64)) as u64)) }

        if (unsafe { tommy_array_get((&raw mut __local_array as *mut tommy_array_struct), __local_i) } != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"array set".ptr) }

    (__local_i = ((0 as u64)))

    while (__local_i < 50000000) {
        unsafe { tommy_array_set((&raw mut __local_array as *mut tommy_array_struct), __local_i, (__local_i as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"array get".ptr) }

    (__local_i = ((0 as u64)))

    while (__local_i < 50000000) {
        if (unsafe { tommy_array_get((&raw mut __local_array as *mut tommy_array_struct), __local_i) } != ((__local_i as *mut c_void))) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    if (unsafe { (*(&raw mut __local_array as *mut tommy_array_struct)).tommy_array_memory_usage() } < 400000000) {
        abort()
    }

    unsafe { (*(&raw mut __local_array as *mut tommy_array_struct)).tommy_array_done() }

}

pub fn test_arrayof() writes compare_counter {
    var __local_arrayof: tommy_arrayof_struct

    var __local_i: u32

    var __local_size: u32 = ((50000000 as u32))

    unsafe { (*(&raw mut __local_arrayof as *mut tommy_arrayof_struct)).tommy_arrayof_init((4 as u64)) }

    unsafe { (*(&raw mut __local_arrayof as *mut tommy_arrayof_struct)).tommy_arrayof_grow((0 as u64)) }

    unsafe { start(c"arrayof init".ptr) }

    (__local_i = ((0 as u32)))

    while (__local_i < 50000000) {
        unsafe { (*(&raw mut __local_arrayof as *mut tommy_arrayof_struct)).tommy_arrayof_grow((((__local_i as u32) +% (1 as u32)) as u64)) }

        var __local_ref: *mut u32 = ((unsafe { tommy_arrayof_ref((&raw mut __local_arrayof as *mut tommy_arrayof_struct), (__local_i as u64)) } as *mut u32))

        if ((unsafe *__local_ref) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"arrayof set".ptr) }

    (__local_i = ((0 as u32)))

    while (__local_i < 50000000) {
        var __local_ref_1: *mut u32 = ((unsafe { tommy_arrayof_ref((&raw mut __local_arrayof as *mut tommy_arrayof_struct), (__local_i as u64)) } as *mut u32))

        ((unsafe *__local_ref_1) = __local_i)


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"arrayof get".ptr) }

    (__local_i = ((0 as u32)))

    while (__local_i < 50000000) {
        var __local_ref_2: *mut u32 = ((unsafe { tommy_arrayof_ref((&raw mut __local_arrayof as *mut tommy_arrayof_struct), (__local_i as u64)) } as *mut u32))

        if ((unsafe *__local_ref_2) != __local_i) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    if (unsafe { (*(&raw mut __local_arrayof as *mut tommy_arrayof_struct)).tommy_arrayof_memory_usage() } < 200000000) {
        abort()
    }

    unsafe { (*(&raw mut __local_arrayof as *mut tommy_arrayof_struct)).tommy_arrayof_done() }

}

pub fn test_arrayblk() writes compare_counter {
    var __local_arrayblk: tommy_arrayblk_struct

    var __local_i: u64

    var __local_size: u32 = ((50000000 as u32))

    unsafe { (*(&raw mut __local_arrayblk as *mut tommy_arrayblk_struct)).tommy_arrayblk_init() }

    unsafe { (*(&raw mut __local_arrayblk as *mut tommy_arrayblk_struct)).tommy_arrayblk_grow((0 as u64)) }

    unsafe { start(c"arrayblk init".ptr) }

    (__local_i = ((0 as u64)))

    while (__local_i < 50000000) {
        unsafe { (*(&raw mut __local_arrayblk as *mut tommy_arrayblk_struct)).tommy_arrayblk_grow((((__local_i as u64) +% (1 as u64)) as u64)) }

        if (unsafe { tommy_arrayblk_get((&raw mut __local_arrayblk as *mut tommy_arrayblk_struct), __local_i) } != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"arrayblk set".ptr) }

    (__local_i = ((0 as u64)))

    while (__local_i < 50000000) {
        unsafe { tommy_arrayblk_set((&raw mut __local_arrayblk as *mut tommy_arrayblk_struct), __local_i, (__local_i as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"arrayblk get".ptr) }

    (__local_i = ((0 as u64)))

    while (__local_i < 50000000) {
        if (unsafe { tommy_arrayblk_get((&raw mut __local_arrayblk as *mut tommy_arrayblk_struct), __local_i) } != ((__local_i as *mut c_void))) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    if (unsafe { (*(&raw mut __local_arrayblk as *mut tommy_arrayblk_struct)).tommy_arrayblk_memory_usage() } < 400000000) {
        abort()
    }

    unsafe { (*(&raw mut __local_arrayblk as *mut tommy_arrayblk_struct)).tommy_arrayblk_done() }

}

pub fn test_arrayblkof() writes compare_counter {
    var __local_arrayblkof: tommy_arrayblkof_struct

    var __local_i: u32

    var __local_size: u32 = ((50000000 as u32))

    unsafe { (*(&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct)).tommy_arrayblkof_init((4 as u64)) }

    unsafe { (*(&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct)).tommy_arrayblkof_grow((0 as u64)) }

    unsafe { start(c"arrayblkof init".ptr) }

    (__local_i = ((0 as u32)))

    while (__local_i < 50000000) {
        unsafe { (*(&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct)).tommy_arrayblkof_grow((((__local_i as u32) +% (1 as u32)) as u64)) }

        var __local_ref: *mut u32 = ((unsafe { tommy_arrayblkof_ref((&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct), (__local_i as u64)) } as *mut u32))

        if ((unsafe *__local_ref) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"arrayblkof set".ptr) }

    (__local_i = ((0 as u32)))

    while (__local_i < 50000000) {
        var __local_ref_1: *mut u32 = ((unsafe { tommy_arrayblkof_ref((&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct), (__local_i as u64)) } as *mut u32))

        ((unsafe *__local_ref_1) = __local_i)


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"arrayblkof get".ptr) }

    (__local_i = ((0 as u32)))

    while (__local_i < 50000000) {
        var __local_ref_2: *mut u32 = ((unsafe { tommy_arrayblkof_ref((&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct), (__local_i as u64)) } as *mut u32))

        if ((unsafe *__local_ref_2) != __local_i) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    if (unsafe { (*(&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct)).tommy_arrayblkof_memory_usage() } < 200000000) {
        abort()
    }

    unsafe { (*(&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct)).tommy_arrayblkof_done() }

}

pub fn test_hashtable() writes compare_counter {
    var __local_hashtable: tommy_hashtable_struct

    var __local_HASH: *mut object_hash

    var __local_i: u32

    var __local_j: u32

    var __local_n: u32


    var __local_limit: u32

    var __local_size: u32 = ((1000000 as u32))

    var __local_module_: u32 = ((250000 as u32))

    (__local_HASH = (((with_alloc(((((1000000 as u64) *% (sizeof[object_hash]() as u64)) as u64) as i64)) as *mut c_void) as *mut object_hash)))

    (__local_i = ((0 as u32)))

    while (__local_i < 1000000) {
        ((unsafe __local_HASH[__local_i]).value = ((((__local_i as u32) % (250000 as u32)) as i32)))

        (__local_i = (__local_i +% 1))

    }


    unsafe { (*(&raw mut __local_hashtable as *mut tommy_hashtable_struct)).tommy_hashtable_init((1 as u64)) }

    if ((unsafe *(&raw const __local_hashtable as *const tommy_hashtable_struct)).bucket_max == 1) {
        abort()
    }

    unsafe { tommy_hashtable_done((&raw mut __local_hashtable as *mut tommy_hashtable_struct)) }

    unsafe { start(c"hashtable stack".ptr) }

    (__local_limit = ((((5 as u32) *% (isqrt((1000000 as u32)) as u32)) as u32)))

    (__local_n = ((0 as u32)))

    while (__local_n <= __local_limit) {
        if (__local_n == __local_limit) {
            (__local_limit = ((1000000 as u32)))

            (__local_n = __local_limit)

        }

        unsafe { (*(&raw mut __local_hashtable as *mut tommy_hashtable_struct)).tommy_hashtable_init((((__local_limit as u32) / (2 as u32)) as u64)) }

        (__local_i = ((0 as u32)))

        while (__local_i < __local_n) {
            unsafe { tommy_hashtable_insert((&raw mut __local_hashtable as *mut tommy_hashtable_struct), ((&raw const (__local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((__local_HASH[__local_i]).value as u64)) }

            (__local_i = (__local_i +% 1))

        }


        if (unsafe { (*(&raw mut __local_hashtable as *mut tommy_hashtable_struct)).tommy_hashtable_memory_usage() } < ((__local_n as u64) *% (sizeof[usize]() as u64))) {
            abort()
        }

        if (unsafe { (*(&raw mut __local_hashtable as *mut tommy_hashtable_struct)).tommy_hashtable_count() } != __local_n) {
            abort()
        }

        (the_count = ((0 as u32)))

        unsafe { (*(&raw mut __local_hashtable as *mut tommy_hashtable_struct)).tommy_hashtable_foreach(count_callback) }

        if (the_count != __local_n) {
            abort()
        }

        (__local_i = ((0 as u32)))

        while (__local_i < ((__local_n as u32) / (2 as u32))) {
            unsafe { tommy_hashtable_remove_existing((&raw mut __local_hashtable as *mut tommy_hashtable_struct), ((&raw const (__local_HASH[((((__local_n as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

            (__local_i = (__local_i +% 1))

        }


        (__local_i = ((0 as u32)))

        while (__local_i < ((__local_n as u32) / (2 as u32))) {
            if (unsafe { tommy_hashtable_remove((&raw mut __local_hashtable as *mut tommy_hashtable_struct), search_callback, (((&raw const (__local_HASH[((((__local_n as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]) as *const object_hash) as *mut object_hash) as *const c_void), ((__local_HASH[((((__local_n as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]).value as u64)) } != 0) {
                abort()
            }

            (__local_i = (__local_i +% 1))

        }


        (__local_i = ((0 as u32)))

        while (__local_i < ((__local_n as u32) / (2 as u32))) {
            if (unsafe { tommy_hashtable_remove((&raw mut __local_hashtable as *mut tommy_hashtable_struct), search_callback, (((&raw const (__local_HASH[((((((__local_n as u32) / (2 as u32)) as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]) as *const object_hash) as *mut object_hash) as *const c_void), ((__local_HASH[((((((__local_n as u32) / (2 as u32)) as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]).value as u64)) } == 0) {
                abort()
            }

            (__local_i = (__local_i +% 1))

        }


        unsafe { tommy_hashtable_done((&raw mut __local_hashtable as *mut tommy_hashtable_struct)) }


        (__local_n = (__local_n +% 1))

    }


    stop()

    unsafe { start(c"hashtable queue".ptr) }

    (__local_limit = ((((isqrt((1000000 as u32)) as u32) / (16 as u32)) as u32)))

    (__local_n = ((0 as u32)))

    while (__local_n <= __local_limit) {
        if (__local_n == __local_limit) {
            (__local_limit = ((1000000 as u32)))

            (__local_n = __local_limit)

        }

        unsafe { (*(&raw mut __local_hashtable as *mut tommy_hashtable_struct)).tommy_hashtable_init((((__local_limit as u32) / (2 as u32)) as u64)) }

        (__local_j = ((0 as u32)))

        (__local_i = ((0 as u32)))


        while (__local_i < __local_n) {
            unsafe { tommy_hashtable_insert((&raw mut __local_hashtable as *mut tommy_hashtable_struct), ((&raw const (__local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((__local_HASH[__local_i]).value as u64)) }

            (__local_i = (__local_i +% 1))

        }


        (the_count = ((0 as u32)))

        unsafe { tommy_hashtable_foreach_arg((&raw mut __local_hashtable as *mut tommy_hashtable_struct), count_arg_callback, ((&raw mut the_count as *mut u32) as *mut c_void)) }

        if (the_count != __local_n) {
            abort()
        }

        while (__local_i < 1000000) {
            unsafe { tommy_hashtable_insert((&raw mut __local_hashtable as *mut tommy_hashtable_struct), ((&raw const (__local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((__local_HASH[__local_i]).value as u64)) }

            unsafe { tommy_hashtable_remove_existing((&raw mut __local_hashtable as *mut tommy_hashtable_struct), ((&raw const (__local_HASH[__local_j]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }


            (__local_i = (__local_i +% 1))

            (__local_j = (__local_j +% 1))


        }

        while (__local_j < 1000000) {
            if (unsafe { tommy_hashtable_remove((&raw mut __local_hashtable as *mut tommy_hashtable_struct), search_callback, (((&raw const (__local_HASH[__local_j]) as *const object_hash) as *mut object_hash) as *const c_void), ((__local_HASH[__local_j]).value as u64)) } == 0) {
                abort()
            }

            (__local_j = (__local_j +% 1))

        }

        unsafe { tommy_hashtable_done((&raw mut __local_hashtable as *mut tommy_hashtable_struct)) }


        (__local_n = (__local_n +% 1))

    }


    stop()

}

pub fn test_hashdyn() writes compare_counter {
    var __local_hashdyn: tommy_hashdyn_struct

    var __local_HASH: *mut object_hash

    var __local_i: u32

    var __local_j: u32

    var __local_n: u32


    var __local_limit: u32

    var __local_size: u32 = ((1000000 as u32))

    var __local_module_: u32 = ((250000 as u32))

    (__local_HASH = (((with_alloc(((((1000000 as u64) *% (sizeof[object_hash]() as u64)) as u64) as i64)) as *mut c_void) as *mut object_hash)))

    (__local_i = ((0 as u32)))

    while (__local_i < 1000000) {
        ((unsafe __local_HASH[__local_i]).value = ((((__local_i as u32) % (250000 as u32)) as i32)))

        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"hashdyn stack".ptr) }

    (__local_limit = ((((5 as u32) *% (isqrt((1000000 as u32)) as u32)) as u32)))

    (__local_n = ((0 as u32)))

    while (__local_n <= __local_limit) {
        if (__local_n == __local_limit) {
            (__local_limit = ((1000000 as u32)))

            (__local_n = __local_limit)

        }

        unsafe { (*(&raw mut __local_hashdyn as *mut tommy_hashdyn_struct)).tommy_hashdyn_init() }

        (__local_i = ((0 as u32)))

        while (__local_i < __local_n) {
            unsafe { tommy_hashdyn_insert((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), ((&raw const (__local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((__local_HASH[__local_i]).value as u64)) }

            (__local_i = (__local_i +% 1))

        }


        if (unsafe { (*(&raw mut __local_hashdyn as *mut tommy_hashdyn_struct)).tommy_hashdyn_memory_usage() } < ((__local_n as u64) *% (sizeof[usize]() as u64))) {
            abort()
        }

        if (unsafe { (*(&raw mut __local_hashdyn as *mut tommy_hashdyn_struct)).tommy_hashdyn_count() } != __local_n) {
            abort()
        }

        (the_count = ((0 as u32)))

        unsafe { (*(&raw mut __local_hashdyn as *mut tommy_hashdyn_struct)).tommy_hashdyn_foreach(count_callback) }

        if (the_count != __local_n) {
            abort()
        }

        (__local_i = ((0 as u32)))

        while (__local_i < ((__local_n as u32) / (2 as u32))) {
            unsafe { tommy_hashdyn_remove_existing((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), ((&raw const (__local_HASH[((((__local_n as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

            (__local_i = (__local_i +% 1))

        }


        (__local_i = ((0 as u32)))

        while (__local_i < ((__local_n as u32) / (2 as u32))) {
            if (unsafe { tommy_hashdyn_remove((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), search_callback, (((&raw const (__local_HASH[((((__local_n as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]) as *const object_hash) as *mut object_hash) as *const c_void), ((__local_HASH[((((__local_n as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]).value as u64)) } != 0) {
                abort()
            }

            (__local_i = (__local_i +% 1))

        }


        (__local_i = ((0 as u32)))

        while (__local_i < ((__local_n as u32) / (2 as u32))) {
            if (unsafe { tommy_hashdyn_remove((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), search_callback, (((&raw const (__local_HASH[((((((__local_n as u32) / (2 as u32)) as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]) as *const object_hash) as *mut object_hash) as *const c_void), ((__local_HASH[((((((__local_n as u32) / (2 as u32)) as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]).value as u64)) } == 0) {
                abort()
            }

            (__local_i = (__local_i +% 1))

        }


        unsafe { tommy_hashdyn_done((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct)) }


        (__local_n = (__local_n +% 1))

    }


    stop()

    unsafe { start(c"hashdyn queue".ptr) }

    (__local_limit = ((((isqrt((1000000 as u32)) as u32) / (16 as u32)) as u32)))

    (__local_n = ((0 as u32)))

    while (__local_n <= __local_limit) {
        if (__local_n == __local_limit) {
            (__local_limit = ((1000000 as u32)))

            (__local_n = __local_limit)

        }

        unsafe { (*(&raw mut __local_hashdyn as *mut tommy_hashdyn_struct)).tommy_hashdyn_init() }

        (__local_j = ((0 as u32)))

        (__local_i = ((0 as u32)))


        while (__local_i < __local_n) {
            unsafe { tommy_hashdyn_insert((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), ((&raw const (__local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((__local_HASH[__local_i]).value as u64)) }

            (__local_i = (__local_i +% 1))

        }


        (the_count = ((0 as u32)))

        unsafe { tommy_hashdyn_foreach_arg((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), count_arg_callback, ((&raw mut the_count as *mut u32) as *mut c_void)) }

        if (the_count != __local_n) {
            abort()
        }

        while (__local_i < 1000000) {
            unsafe { tommy_hashdyn_insert((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), ((&raw const (__local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((__local_HASH[__local_i]).value as u64)) }

            unsafe { tommy_hashdyn_remove_existing((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), ((&raw const (__local_HASH[__local_j]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }


            (__local_i = (__local_i +% 1))

            (__local_j = (__local_j +% 1))


        }

        while (__local_j < 1000000) {
            if (unsafe { tommy_hashdyn_remove((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), search_callback, (((&raw const (__local_HASH[__local_j]) as *const object_hash) as *mut object_hash) as *const c_void), ((__local_HASH[__local_j]).value as u64)) } == 0) {
                abort()
            }

            (__local_j = (__local_j +% 1))

        }

        unsafe { tommy_hashdyn_done((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct)) }


        (__local_n = (__local_n +% 1))

    }


    stop()

}

pub fn test_hashlin() writes compare_counter {
    var __local_hashlin: tommy_hashlin_struct

    var __local_HASH: *mut object_hash

    var __local_i: u32

    var __local_j: u32

    var __local_n: u32


    var __local_limit: u32

    var __local_size: u32 = ((1000000 as u32))

    var __local_module_: u32 = ((250000 as u32))

    var __local_bucket: *mut tommy_node_struct

    (__local_HASH = (((with_alloc(((((1000000 as u64) *% (sizeof[object_hash]() as u64)) as u64) as i64)) as *mut c_void) as *mut object_hash)))

    (__local_i = ((0 as u32)))

    while (__local_i < 1000000) {
        ((unsafe __local_HASH[__local_i]).value = ((((__local_i as u32) % (250000 as u32)) as i32)))

        (__local_i = (__local_i +% 1))

    }


    unsafe { (*(&raw mut __local_hashlin as *mut tommy_hashlin_struct)).tommy_hashlin_init() }

    (__local_i = ((0 as u32)))

    while (__local_i < 1000000) {
        unsafe { tommy_hashlin_insert((&raw mut __local_hashlin as *mut tommy_hashlin_struct), ((&raw const (__local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((__local_HASH[__local_i]).value as u64)) }

        (__local_i = (__local_i +% 1))

    }


    (__local_bucket = unsafe { tommy_hashlin_bucket((&raw mut __local_hashlin as *mut tommy_hashlin_struct), (249999 as u64)) })

    if (__local_bucket == 0) {
        abort()
    }

    unsafe { (*(&raw mut __local_hashlin as *mut tommy_hashlin_struct)).tommy_hashlin_done() }

    unsafe { start(c"hashlin stack".ptr) }

    (__local_limit = ((((5 as u32) *% (isqrt((1000000 as u32)) as u32)) as u32)))

    (__local_n = ((0 as u32)))

    while (__local_n <= __local_limit) {
        if (__local_n == __local_limit) {
            (__local_limit = ((1000000 as u32)))

            (__local_n = __local_limit)

        }

        unsafe { (*(&raw mut __local_hashlin as *mut tommy_hashlin_struct)).tommy_hashlin_init() }

        (__local_i = ((0 as u32)))

        while (__local_i < __local_n) {
            unsafe { tommy_hashlin_insert((&raw mut __local_hashlin as *mut tommy_hashlin_struct), ((&raw const (__local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((__local_HASH[__local_i]).value as u64)) }

            (__local_i = (__local_i +% 1))

        }


        if (unsafe { (*(&raw mut __local_hashlin as *mut tommy_hashlin_struct)).tommy_hashlin_memory_usage() } < ((__local_n as u64) *% (sizeof[usize]() as u64))) {
            abort()
        }

        if (unsafe { (*(&raw mut __local_hashlin as *mut tommy_hashlin_struct)).tommy_hashlin_count() } != __local_n) {
            abort()
        }

        (the_count = ((0 as u32)))

        unsafe { (*(&raw mut __local_hashlin as *mut tommy_hashlin_struct)).tommy_hashlin_foreach(count_callback) }

        if (the_count != __local_n) {
            abort()
        }

        (__local_i = ((0 as u32)))

        while (__local_i < ((__local_n as u32) / (2 as u32))) {
            unsafe { tommy_hashlin_remove_existing((&raw mut __local_hashlin as *mut tommy_hashlin_struct), ((&raw const (__local_HASH[((((__local_n as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

            (__local_i = (__local_i +% 1))

        }


        (__local_i = ((0 as u32)))

        while (__local_i < ((__local_n as u32) / (2 as u32))) {
            if (unsafe { tommy_hashlin_remove((&raw mut __local_hashlin as *mut tommy_hashlin_struct), search_callback, (((&raw const (__local_HASH[((((__local_n as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]) as *const object_hash) as *mut object_hash) as *const c_void), ((__local_HASH[((((__local_n as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]).value as u64)) } != 0) {
                abort()
            }

            (__local_i = (__local_i +% 1))

        }


        (__local_i = ((0 as u32)))

        while (__local_i < ((__local_n as u32) / (2 as u32))) {
            if (unsafe { tommy_hashlin_remove((&raw mut __local_hashlin as *mut tommy_hashlin_struct), search_callback, (((&raw const (__local_HASH[((((((__local_n as u32) / (2 as u32)) as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]) as *const object_hash) as *mut object_hash) as *const c_void), ((__local_HASH[((((((__local_n as u32) / (2 as u32)) as u32) -% (__local_i as u32)) as u32) -% (1 as u32))]).value as u64)) } == 0) {
                abort()
            }

            (__local_i = (__local_i +% 1))

        }


        unsafe { (*(&raw mut __local_hashlin as *mut tommy_hashlin_struct)).tommy_hashlin_done() }


        (__local_n = (__local_n +% 1))

    }


    stop()

    unsafe { start(c"hashlin queue".ptr) }

    (__local_limit = ((((isqrt((1000000 as u32)) as u32) / (16 as u32)) as u32)))

    (__local_n = ((0 as u32)))

    while (__local_n <= __local_limit) {
        if (__local_n == __local_limit) {
            (__local_limit = ((1000000 as u32)))

            (__local_n = __local_limit)

        }

        unsafe { (*(&raw mut __local_hashlin as *mut tommy_hashlin_struct)).tommy_hashlin_init() }

        (__local_j = ((0 as u32)))

        (__local_i = ((0 as u32)))


        while (__local_i < __local_n) {
            unsafe { tommy_hashlin_insert((&raw mut __local_hashlin as *mut tommy_hashlin_struct), ((&raw const (__local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((__local_HASH[__local_i]).value as u64)) }

            (__local_i = (__local_i +% 1))

        }


        (the_count = ((0 as u32)))

        unsafe { tommy_hashlin_foreach_arg((&raw mut __local_hashlin as *mut tommy_hashlin_struct), count_arg_callback, ((&raw mut the_count as *mut u32) as *mut c_void)) }

        if (the_count != __local_n) {
            abort()
        }

        while (__local_i < 1000000) {
            unsafe { tommy_hashlin_insert((&raw mut __local_hashlin as *mut tommy_hashlin_struct), ((&raw const (__local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((__local_HASH[__local_i]).value as u64)) }

            unsafe { tommy_hashlin_remove_existing((&raw mut __local_hashlin as *mut tommy_hashlin_struct), ((&raw const (__local_HASH[__local_j]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }


            (__local_i = (__local_i +% 1))

            (__local_j = (__local_j +% 1))


        }

        while (__local_j < 1000000) {
            if (unsafe { tommy_hashlin_remove((&raw mut __local_hashlin as *mut tommy_hashlin_struct), search_callback, (((&raw const (__local_HASH[__local_j]) as *const object_hash) as *mut object_hash) as *const c_void), ((__local_HASH[__local_j]).value as u64)) } == 0) {
                abort()
            }

            (__local_j = (__local_j +% 1))

        }

        unsafe { (*(&raw mut __local_hashlin as *mut tommy_hashlin_struct)).tommy_hashlin_done() }


        (__local_n = (__local_n +% 1))

    }


    stop()

}

pub fn test_trie() writes compare_counter {
    var __local_trie: tommy_trie_struct

    var __local_alloc: tommy_allocator_struct

    var __local_OBJ: *mut object_trie

    var __local_DUP: List[object_trie] = [object_trie.zeroed(); 2]

    var __local_i: u32

    var __local_size: u32 = ((4000000 as u32))

    (__local_OBJ = (((with_alloc(((((4000000 as u64) *% (sizeof[object_trie]() as u64)) as u64) as i64)) as *mut c_void) as *mut object_trie)))

    (__local_i = ((0 as u32)))

    while (__local_i < 4000000) {
        ((unsafe __local_OBJ[__local_i]).value = ((__local_i as i32)))

        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"trie".ptr) }

    unsafe { (*(&raw mut __local_alloc as *mut tommy_allocator_struct)).tommy_allocator_init((64 as u64), (64 as u64)) }

    unsafe { tommy_trie_init((&raw mut __local_trie as *mut tommy_trie_struct), (&raw mut __local_alloc as *mut tommy_allocator_struct)) }

    (__local_i = ((0 as u32)))

    while (__local_i < 4000000) {
        unsafe { tommy_trie_insert((&raw mut __local_trie as *mut tommy_trie_struct), ((&raw const (__local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (__local_OBJ[__local_i]) as *const object_trie) as *mut object_trie) as *mut c_void), ((__local_OBJ[__local_i]).value as u64)) }

        (__local_i = (__local_i +% 1))

    }


    if (unsafe { (*(&raw mut __local_trie as *mut tommy_trie_struct)).tommy_trie_memory_usage() } < 128000000) {
        abort()
    }

    if (unsafe { (*(&raw mut __local_alloc as *mut tommy_allocator_struct)).tommy_allocator_memory_usage() } < (((unsafe *(&raw const __local_trie as *const tommy_trie_struct)).node_count as u64) *% (64 as u64))) {
        abort()
    }

    if (unsafe { (*(&raw mut __local_trie as *mut tommy_trie_struct)).tommy_trie_count() } != 4000000) {
        abort()
    }

    (__local_i = ((0 as u32)))

    while (__local_i < 2) {
        (__local_DUP[__local_i].value = ((0 as i32)))

        unsafe { tommy_trie_insert((&raw mut __local_trie as *mut tommy_trie_struct), ((&raw const __local_DUP[__local_i].node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const __local_DUP[__local_i] as *const object_trie) as *mut object_trie) as *mut c_void), (__local_DUP[__local_i].value as u64)) }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < ((4000000 as u32) / (2 as u32))) {
        if (unsafe { tommy_trie_search((&raw mut __local_trie as *mut tommy_trie_struct), ((__local_OBJ[__local_i]).value as u64)) } == 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    unsafe { tommy_trie_remove_existing((&raw mut __local_trie as *mut tommy_trie_struct), ((&raw const __local_DUP[0].node as *const tommy_node_struct) as *mut tommy_node_struct)) }

    (__local_i = ((0 as u32)))

    while (__local_i < ((4000000 as u32) / (2 as u32))) {
        unsafe { tommy_trie_remove_existing((&raw mut __local_trie as *mut tommy_trie_struct), ((&raw const (__local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

        (__local_i = (__local_i +% 1))

    }


    if (unsafe { (*(&raw mut __local_trie as *mut tommy_trie_struct)).tommy_trie_remove((1 as u64)) } != 0) {
        abort()
    }

    if (unsafe { tommy_trie_search((&raw mut __local_trie as *mut tommy_trie_struct), (1 as u64)) } != 0) {
        abort()
    }

    unsafe { tommy_trie_remove_existing((&raw mut __local_trie as *mut tommy_trie_struct), ((&raw const __local_DUP[1].node as *const tommy_node_struct) as *mut tommy_node_struct)) }

    (__local_i = ((0 as u32)))

    while (__local_i < ((4000000 as u32) / (2 as u32))) {
        if (unsafe { (*(&raw mut __local_trie as *mut tommy_trie_struct)).tommy_trie_remove(((__local_OBJ[__local_i]).value as u64)) } != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < ((4000000 as u32) / (2 as u32))) {
        if (unsafe { tommy_trie_search((&raw mut __local_trie as *mut tommy_trie_struct), ((__local_OBJ[__local_i]).value as u64)) } != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < ((4000000 as u32) / (2 as u32))) {
        if (unsafe { (*(&raw mut __local_trie as *mut tommy_trie_struct)).tommy_trie_remove(((__local_OBJ[((((4000000 as u32) / (2 as u32)) as u32) +% (__local_i as u32))]).value as u64)) } == 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    unsafe { (*(&raw mut __local_alloc as *mut tommy_allocator_struct)).tommy_allocator_done() }

    stop()

}

pub fn test_trie_inplace() writes compare_counter {
    var __local_trie_inplace: tommy_trie_inplace_struct

    var __local_OBJ: *mut object_trie_inplace

    var __local_DUP: List[object_trie_inplace] = [object_trie_inplace.zeroed(); 2]

    var __local_i: u32

    var __local_size: u32 = ((4000000 as u32))

    (__local_OBJ = (((with_alloc(((((4000000 as u64) *% (sizeof[object_trie_inplace]() as u64)) as u64) as i64)) as *mut c_void) as *mut object_trie_inplace)))

    (__local_i = ((0 as u32)))

    while (__local_i < 4000000) {
        ((unsafe __local_OBJ[__local_i]).value = ((__local_i as i32)))

        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"trie_inplace".ptr) }

    unsafe { (*(&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct)).tommy_trie_inplace_init() }

    (__local_i = ((0 as u32)))

    while (__local_i < 4000000) {
        unsafe { tommy_trie_inplace_insert((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((&raw const (__local_OBJ[__local_i]).node as *const tommy_trie_inplace_node_struct) as *mut tommy_trie_inplace_node_struct), (((&raw const (__local_OBJ[__local_i]) as *const object_trie_inplace) as *mut object_trie_inplace) as *mut c_void), ((__local_OBJ[__local_i]).value as u64)) }

        (__local_i = (__local_i +% 1))

    }


    if (unsafe { (*(&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct)).tommy_trie_inplace_memory_usage() } < 256000000) {
        abort()
    }

    if (unsafe { (*(&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct)).tommy_trie_inplace_count() } != 4000000) {
        abort()
    }

    (__local_i = ((0 as u32)))

    while (__local_i < 2) {
        (__local_DUP[__local_i].value = ((0 as i32)))

        unsafe { tommy_trie_inplace_insert((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((&raw const __local_DUP[__local_i].node as *const tommy_trie_inplace_node_struct) as *mut tommy_trie_inplace_node_struct), (((&raw const __local_DUP[__local_i] as *const object_trie_inplace) as *mut object_trie_inplace) as *mut c_void), (__local_DUP[__local_i].value as u64)) }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < ((4000000 as u32) / (2 as u32))) {
        if (unsafe { tommy_trie_inplace_search((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((__local_OBJ[__local_i]).value as u64)) } == 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    unsafe { tommy_trie_inplace_remove_existing((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((&raw const __local_DUP[0].node as *const tommy_trie_inplace_node_struct) as *mut tommy_trie_inplace_node_struct)) }

    (__local_i = ((0 as u32)))

    while (__local_i < ((4000000 as u32) / (2 as u32))) {
        unsafe { tommy_trie_inplace_remove_existing((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((&raw const (__local_OBJ[__local_i]).node as *const tommy_trie_inplace_node_struct) as *mut tommy_trie_inplace_node_struct)) }

        (__local_i = (__local_i +% 1))

    }


    unsafe { tommy_trie_inplace_remove_existing((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((&raw const __local_DUP[1].node as *const tommy_trie_inplace_node_struct) as *mut tommy_trie_inplace_node_struct)) }

    (__local_i = ((0 as u32)))

    while (__local_i < ((4000000 as u32) / (2 as u32))) {
        if (unsafe { (*(&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct)).tommy_trie_inplace_remove(((__local_OBJ[__local_i]).value as u64)) } != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < ((4000000 as u32) / (2 as u32))) {
        if (unsafe { tommy_trie_inplace_search((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((__local_OBJ[__local_i]).value as u64)) } != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < ((4000000 as u32) / (2 as u32))) {
        if (unsafe { (*(&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct)).tommy_trie_inplace_remove(((__local_OBJ[((((4000000 as u32) / (2 as u32)) as u32) +% (__local_i as u32))]).value as u64)) } == 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    stop()

}

pub fn main() -> i32 writes SEED, compare_counter {
    nano_init()

    printf(c"Tommy check program.\n".ptr)

    test_hash()

    test_alloc()

    test_list()

    test_tree()

    test_array()

    test_arrayof()

    test_arrayblk()

    test_arrayblkof()

    test_hashtable()

    test_hashdyn()

    test_hashlin()

    test_trie()

    test_trie_inplace()

    printf(c"OK\n".ptr)

    return libc.EXIT_SUCCESS

}

let the_cache: List[u8] = [0; 16777216]
var the_str: *const c_char = null
var the_start: u64 = 0
var the_count: u32 = 0
