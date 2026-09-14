// Migrated from C
use std.tommyds.defs
use std.tommyds.tommyhash
use std.tommyds.tommyalloc
use std.tommyds.tommyarray
use std.tommyds.tommyarrayof
use std.tommyds.tommyarrayblk
use std.tommyds.tommyarrayblkof
use std.tommyds.tommylist
use std.tommyds.tommytree
use std.tommyds.tommytrie
use std.tommyds.tommytrieinp
use std.tommyds.tommyhashtbl
use std.tommyds.tommyhashdyn
use std.tommyds.tommyhashlin
use std.libc

fn tommy_ilog2_u32(__param_value: c_uint) -> c_uint {
    return (((__param_value as u32).clz() as c_int) ^ (31 as c_int))

}

fn tommy_ilog2_u64(__param_value: c_ulonglong) -> c_uint {
    return (((__param_value as u64).clz() as c_int) ^ (63 as c_int))

}

fn tommy_ctz_u32(__param_value: c_uint) -> c_uint {
    return (((__param_value as u32).ctz() as c_uint))

}

fn tommy_ctz_u64(__param_value: c_ulonglong) -> c_uint {
    return (((__param_value as u64).ctz() as c_uint))

}

fn tommy_roundup_pow2_u32(__param_value: c_uint) -> c_uint {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (1 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (2 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (4 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (8 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (16 as c_uint)) as c_uint))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_roundup_pow2_u64(__param_value: c_ulonglong) -> c_ulonglong {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (1 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (2 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (4 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (8 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (16 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (32 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_haszero_u32(__param_value: c_uint) -> c_int {
    return (if ((((((__param_value as c_uint) -% (16843009 as c_uint)) as c_uint) & ((~__param_value) as c_uint)) as c_uint) & ((2155905152 as c_uint) as c_uint)) != 0: 1 else: 0)

}

pub unsafe fn compare(__param_void_a: *const c_void, __param_void_b: *const c_void) -> c_int {
    var __local_a: *const object = ((__param_void_a as *const object))

    var __local_b: *const object = ((__param_void_b as *const object))

    (compare_counter = (compare_counter +% 1))

    if ((if (unsafe *__local_a).value < (unsafe *__local_b).value: 1 else: 0) != 0) {
        return -1
    }

    if ((if (unsafe *__local_a).value > (unsafe *__local_b).value: 1 else: 0) != 0) {
        return 1
    }

    return 0

}

pub unsafe fn compare_vector(__param_void_a: *const c_void, __param_void_b: *const c_void) -> c_int {
    var __local_a: *const object_vector = ((__param_void_a as *const object_vector))

    var __local_b: *const object_vector = ((__param_void_b as *const object_vector))

    (compare_counter = (compare_counter +% 1))

    if ((if (unsafe *__local_a).value < (unsafe *__local_b).value: 1 else: 0) != 0) {
        return -1
    }

    if ((if (unsafe *__local_a).value > (unsafe *__local_b).value: 1 else: 0) != 0) {
        return 1
    }

    return 0

}

fn nano_init() -> Unit {
    return
}

fn nano() -> c_ulonglong {
    var __local_ret: c_ulonglong

    var __local_info: mach_timebase_info

    var __local_r: c_int

    var __local_t: c_ulonglong

    (__local_t = ((mach_absolute_time() as c_ulonglong)))

    (__local_r = ((unsafe { mach_timebase_info((&raw mut __local_info as *mut mach_timebase_info)) } as c_int)))

    if ((if __local_r != 0: 1 else: 0) != 0) {
        abort()
    }

    (__local_ret = ((((((__local_t as c_ulonglong) / ((unsafe *(&raw const __local_info as *const mach_timebase_info)).denom as c_ulonglong)) as c_ulonglong) *% ((unsafe *(&raw const __local_info as *const mach_timebase_info)).numer as c_ulonglong)) as c_ulonglong)))

    (__local_ret = (__local_ret +% ((((((__local_t as c_ulonglong) % ((unsafe *(&raw const __local_info as *const mach_timebase_info)).denom as c_ulonglong)) as c_ulonglong) *% ((unsafe *(&raw const __local_info as *const mach_timebase_info)).numer as c_ulonglong)) as c_ulonglong) / ((unsafe *(&raw const __local_info as *const mach_timebase_info)).denom as c_ulonglong))))

    return __local_ret

}

pub fn rnd(__param_max: c_uint) -> c_uint {
    var __local_r__goto_208_11: c_uint = 0

    var __local_divider__goto_209_17: c_ulonglong = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        (__local_divider__goto_209_17 = ((((((0 as c_ulonglong) -% 1) as c_ulonglong) / (__param_max as c_ulonglong)) as c_ulonglong)))
        (SEED = ((((((SEED as c_ulonglong) *% ((6364136223846793005 as c_ulonglong) as c_ulonglong)) as c_ulonglong) +% ((1442695040888963407 as c_ulonglong) as c_ulonglong)) as c_ulonglong)))
        (__local_r__goto_208_11 = ((((SEED as c_ulonglong) / (__local_divider__goto_209_17 as c_ulonglong)) as c_uint)))
        if ((if __local_r__goto_208_11 >= __param_max: 1 else: 0) != 0) {
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

pub fn isqrt(__param_n: c_uint) -> c_uint {
    var __local_root: c_uint

    var __local_remain: c_uint

    var __local_place: c_uint


    (__local_root = ((0 as c_uint)))

    (__local_remain = __param_n)

    (__local_place = ((1073741824 as c_uint)))

    while ((if __local_place > __local_remain: 1 else: 0) != 0) {
        (__local_place = __local_place / 4)
    }

    while (__local_place != 0) {
        if ((if __local_remain >= ((__local_root as c_uint) +% (__local_place as c_uint)): 1 else: 0) != 0) {
            (__local_remain = (__local_remain -% ((__local_root as c_uint) +% (__local_place as c_uint))))

            (__local_root = (__local_root +% ((2 as c_uint) *% (__local_place as c_uint))))

        }

        (__local_root = __local_root / 2)

        (__local_place = __local_place / 4)

    }

    return __local_root

}

pub fn cache_clear() -> Unit {
    var __local_i: c_uint

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (16777216 * sizeof[u8]()): 1 else: 0) != 0) {
        (the_cache[__local_i] = ((the_cache[__local_i] as c_int) +% (1 as u8)))

        (__local_i = (__local_i +% 32))

    }


}

pub unsafe fn start(__param_str: *const i8) -> Unit {
    cache_clear()

    (compare_counter = ((0 as c_uint)))

    (the_str = ((__param_str as *const c_char)))

    (the_start = ((nano() as c_ulonglong)))

}

pub fn stop(...) -> Unit {
    var __local_the_stop: c_ulonglong = ((nano() as c_ulonglong))

    printf(c"%25s %8u [ms], %8u [compare]\n".ptr, the_str, (((((__local_the_stop as c_ulonglong) -% (the_start as c_ulonglong)) as c_ulonglong) / (1000000 as c_ulonglong)) as c_uint), compare_counter)

}

unsafe fn count_callback(__param_data: *mut c_void) -> Unit {
    __param_data

    (the_count = (the_count +% 1))

}

unsafe fn count_arg_callback(__param_arg: *mut c_void, __param_data: *mut c_void) -> Unit {
    var __local_count: *mut c_uint = ((__param_arg as *mut c_uint))

    __param_data

    ((unsafe *__local_count) = ((unsafe *__local_count) +% 1))

}

unsafe fn search_callback(__param_arg: *const c_void, __param_obj: *const c_void) -> c_int {
    return (if __param_arg != __param_obj: 1 else: 0)

}

pub fn test_hash() -> Unit {
    var __local_i: c_uint

    var __local_buffer: [16]u8

    var __local_COUNT: c_uint = ((16777216 as c_uint))

    var __local_hash32: c_uint

    var __local_hash64: c_ulonglong

    unsafe { start(c"hash_test_vectors".ptr) }

    (__local_i = ((0 as c_uint)))

    while (HASH32[__local_i].data != null) {
        if ((if unsafe { tommy_hash_u32((2808510813 as c_uint), (HASH32[__local_i].data as *const c_void), (HASH32[__local_i].len as c_ulonglong)) } != HASH32[__local_i].hash: 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while (STRHASH32[__local_i].data != null) {
        if ((if unsafe { tommy_strhash_u32((2808510813 as c_uint), (STRHASH32[__local_i].data as *const c_void)) } != STRHASH32[__local_i].hash: 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while (HASH64[__local_i].data != null) {
        if ((if unsafe { tommy_hash_u64((3387313247419267421 as c_ulonglong), (HASH64[__local_i].data as *const c_void), (HASH64[__local_i].len as c_ulonglong)) } != HASH64[__local_i].hash: 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while true {
        var __ci_expr_logic_0: c_int

        if (INTHASH32[__local_i].value != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if not (__local_i != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        if ((if tommy_inthash_u32(INTHASH32[__local_i].value) != INTHASH32[__local_i].hash: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while true {
        var __ci_expr_logic_1: c_int

        if (INTHASH64[__local_i].value != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if not (__local_i != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        if ((if tommy_inthash_u64(INTHASH64[__local_i].value) != INTHASH64[__local_i].hash: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { with_memset(((&__local_buffer[0] as *mut u8) as *mut u8), (170 as c_int), (((16 * sizeof[u8]()) as c_ulong) as i64)) }

    (__local_buffer[(((16 * sizeof[u8]()) as c_ulong) -% (1 as c_ulong))] = ((0 as u8)))

    (__local_hash32 = ((0 as c_uint)))

    (__local_hash64 = ((0 as c_ulonglong)))

    unsafe { start(c"hash_u32".ptr) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_COUNT: 1 else: 0) != 0) {
        (__local_hash32 = ((unsafe { tommy_hash_u32(__local_hash32, (&__local_buffer[0] as *mut u8), (16 as c_ulonglong)) } as c_uint)))


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"strhash_u32".ptr) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_COUNT: 1 else: 0) != 0) {
        (__local_hash32 = ((unsafe { tommy_strhash_u32(__local_hash32, (&__local_buffer[0] as *mut u8)) } as c_uint)))


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"hash_u64".ptr) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_COUNT: 1 else: 0) != 0) {
        (__local_hash64 = ((unsafe { tommy_hash_u64(__local_hash64, (&__local_buffer[0] as *mut u8), (16 as c_ulonglong)) } as c_ulonglong)))


        (__local_i = (__local_i +% 1))

    }


    stop()

}

pub fn test_alloc() -> Unit {
    var __local_size: c_uint = ((10000000 as c_uint))

    var __local_i: c_uint

    var __local_alloc: tommy_allocator_struct

    var __local_PTR: *mut *mut c_void

    (__local_PTR = (((unsafe { with_alloc(((((10000000 as c_ulong) *% (sizeof[usize]() as c_ulong)) as c_ulong) as i64)) } as *mut c_void) as *mut *mut c_void)))

    unsafe { tommy_allocator_init((&raw mut __local_alloc as *mut tommy_allocator_struct), (8 as c_ulonglong), (1 as c_ulonglong)) }

    if ((if (unsafe *(&raw const __local_alloc as *const tommy_allocator_struct)).align_size < 8: 1 else: 0) != 0) {
        abort()
    }

    unsafe { tommy_allocator_done((&raw mut __local_alloc as *mut tommy_allocator_struct)) }

    unsafe { tommy_allocator_init((&raw mut __local_alloc as *mut tommy_allocator_struct), (7 as c_ulonglong), (8 as c_ulonglong)) }

    if ((if (unsafe *(&raw const __local_alloc as *const tommy_allocator_struct)).block_size != 8: 1 else: 0) != 0) {
        abort()
    }

    unsafe { tommy_allocator_done((&raw mut __local_alloc as *mut tommy_allocator_struct)) }

    unsafe { tommy_allocator_init((&raw mut __local_alloc as *mut tommy_allocator_struct), (128000 as c_ulonglong), (64 as c_ulonglong)) }

    if ((if unsafe { tommy_allocator_alloc((&raw mut __local_alloc as *mut tommy_allocator_struct)) } == 0: 1 else: 0) != 0) {
        abort()
    }

    unsafe { tommy_allocator_done((&raw mut __local_alloc as *mut tommy_allocator_struct)) }

    unsafe { tommy_allocator_init((&raw mut __local_alloc as *mut tommy_allocator_struct), (64 as c_ulonglong), (64 as c_ulonglong)) }

    unsafe { start(c"alloc".ptr) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 10000000: 1 else: 0) != 0) {
        ((unsafe __local_PTR[__local_i]) = unsafe { tommy_allocator_alloc((&raw mut __local_alloc as *mut tommy_allocator_struct)) })


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"free".ptr) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 10000000: 1 else: 0) != 0) {
        unsafe { tommy_allocator_free((&raw mut __local_alloc as *mut tommy_allocator_struct), (unsafe __local_PTR[__local_i])) }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { tommy_allocator_done((&raw mut __local_alloc as *mut tommy_allocator_struct)) }

    unsafe { with_free(((__local_PTR as *mut c_void) as *mut u8)) }

}

pub unsafe fn test_list_order(__param_list: *mut tommy_node_struct) -> Unit {
    var __local_node: *mut tommy_node_struct

    (__local_node = __param_list)

    while (__local_node != null) {
        if ((unsafe *__local_node).next != null) {
            var __local_a: *const object = (((unsafe *__local_node).data as *const object))

            var __local_b: *const object = (((unsafe *(unsafe *__local_node).next).data as *const object))

            if ((if (unsafe *__local_a).value > (unsafe *__local_b).value: 1 else: 0) != 0) {
                abort()
            }

            var __ci_expr_logic_0: c_int = 0

            if ((if (unsafe *__local_a).value == (unsafe *__local_b).value: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if __local_a > __local_b: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                abort()
            }


        }

        (__local_node = (unsafe *__local_node).next)

    }

}

pub fn test_list() -> Unit {
    var __local_LIST: *mut object

    var __local_VECTOR: *mut object_vector

    var __local_list: *mut tommy_node_struct

    var __local_i: c_uint

    var __local_size: c_uint = ((1000000 as c_uint))

    (__local_LIST = (((unsafe { with_alloc(((((1000000 as c_ulong) *% (sizeof[object]() as c_ulong)) as c_ulong) as i64)) } as *mut c_void) as *mut object)))

    (__local_VECTOR = (((unsafe { with_alloc(((((1000000 as c_ulong) *% (sizeof[object_vector]() as c_ulong)) as c_ulong) as i64)) } as *mut c_void) as *mut object_vector)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 1000000: 1 else: 0) != 0) {
        ((unsafe __local_LIST[__local_i]).value = ((0 as c_int)))

        ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)



        (__local_i = (__local_i +% 1))

    }


    unsafe { tommy_list_init((&raw mut __local_list as *mut *mut tommy_node_struct)) }

    unsafe { tommy_list_sort((&raw mut __local_list as *mut *mut tommy_node_struct), compare) }

    if ((if not (unsafe { tommy_list_empty((&raw mut __local_list as *mut *mut tommy_node_struct)) } != 0): 1 else: 0) != 0) {
        abort()
    }

    if ((if unsafe { tommy_list_tail((&raw mut __local_list as *mut *mut tommy_node_struct)) } != 0: 1 else: 0) != 0) {
        abort()
    }

    if ((if unsafe { tommy_list_head((&raw mut __local_list as *mut *mut tommy_node_struct)) } != 0: 1 else: 0) != 0) {
        abort()
    }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 1000000: 1 else: 0) != 0) {
        ((unsafe __local_LIST[__local_i]).value = ((rnd((1000000 as c_uint)) as c_int)))

        ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)


        unsafe { tommy_list_insert_tail((&raw mut __local_list as *mut *mut tommy_node_struct), ((&raw const (unsafe __local_LIST[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_LIST[__local_i]) as *const object) as *mut object) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    if ((if unsafe { tommy_list_tail((&raw mut __local_list as *mut *mut tommy_node_struct)) } == 0: 1 else: 0) != 0) {
        abort()
    }

    if ((if unsafe { tommy_list_head((&raw mut __local_list as *mut *mut tommy_node_struct)) } == 0: 1 else: 0) != 0) {
        abort()
    }

    unsafe { start(c"sort random".ptr) }

    unsafe { tommy_list_sort((&raw mut __local_list as *mut *mut tommy_node_struct), compare) }

    stop()

    unsafe { start(c"C qsort random".ptr) }

    qsort((__local_VECTOR as *mut c_void), (1000000 as c_ulong), (sizeof[object_vector]() as c_ulong), compare_vector)

    stop()

    unsafe { test_list_order(__local_list) }

    (__local_list = null)

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 1000000: 1 else: 0) != 0) {
        ((unsafe __local_LIST[__local_i]).value = ((__local_i as c_int)))

        ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)


        if ((if rnd((100 as c_uint)) == 0: 1 else: 0) != 0) {
            ((unsafe __local_LIST[__local_i]).value = ((rnd((1000000 as c_uint)) as c_int)))

            ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)

        }

        unsafe { tommy_list_insert_tail((&raw mut __local_list as *mut *mut tommy_node_struct), ((&raw const (unsafe __local_LIST[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_LIST[__local_i]) as *const object) as *mut object) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"sort partially ordered".ptr) }

    unsafe { tommy_list_sort((&raw mut __local_list as *mut *mut tommy_node_struct), compare) }

    stop()

    unsafe { start(c"C qsort partially ordered".ptr) }

    qsort((__local_VECTOR as *mut c_void), (1000000 as c_ulong), (sizeof[object_vector]() as c_ulong), compare_vector)

    stop()

    unsafe { test_list_order(__local_list) }

    (__local_list = null)

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 1000000: 1 else: 0) != 0) {
        ((unsafe __local_LIST[__local_i]).value = ((__local_i as c_int)))

        ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)


        unsafe { tommy_list_insert_tail((&raw mut __local_list as *mut *mut tommy_node_struct), ((&raw const (unsafe __local_LIST[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_LIST[__local_i]) as *const object) as *mut object) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"sort forward".ptr) }

    unsafe { tommy_list_sort((&raw mut __local_list as *mut *mut tommy_node_struct), compare) }

    stop()

    unsafe { start(c"C qsort forward".ptr) }

    qsort((__local_VECTOR as *mut c_void), (1000000 as c_ulong), (sizeof[object_vector]() as c_ulong), compare_vector)

    stop()

    unsafe { test_list_order(__local_list) }

    (__local_list = null)

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 1000000: 1 else: 0) != 0) {
        ((unsafe __local_LIST[__local_i]).value = ((((((1000000 as c_uint) -% (1 as c_uint)) as c_uint) -% (__local_i as c_uint)) as c_int)))

        ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)


        unsafe { tommy_list_insert_tail((&raw mut __local_list as *mut *mut tommy_node_struct), ((&raw const (unsafe __local_LIST[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_LIST[__local_i]) as *const object) as *mut object) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"sort backward".ptr) }

    unsafe { tommy_list_sort((&raw mut __local_list as *mut *mut tommy_node_struct), compare) }

    stop()

    unsafe { start(c"C qsort backward".ptr) }

    qsort((__local_VECTOR as *mut c_void), (1000000 as c_ulong), (sizeof[object_vector]() as c_ulong), compare_vector)

    stop()

    unsafe { test_list_order(__local_list) }

    (__local_list = null)

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 1000000: 1 else: 0) != 0) {
        ((unsafe __local_LIST[__local_i]).value = ((rnd((((((1000000 as c_uint) / (1000 as c_uint)) as c_uint) +% (2 as c_uint)) as c_uint)) as c_int)))

        ((unsafe __local_VECTOR[__local_i]).value = (unsafe __local_LIST[__local_i]).value)


        unsafe { tommy_list_insert_tail((&raw mut __local_list as *mut *mut tommy_node_struct), ((&raw const (unsafe __local_LIST[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_LIST[__local_i]) as *const object) as *mut object) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"sort random duplicate".ptr) }

    unsafe { tommy_list_sort((&raw mut __local_list as *mut *mut tommy_node_struct), compare) }

    stop()

    unsafe { start(c"C qsort random duplicate".ptr) }

    qsort((__local_VECTOR as *mut c_void), (1000000 as c_ulong), (sizeof[object_vector]() as c_ulong), compare_vector)

    stop()

    unsafe { test_list_order(__local_list) }

    unsafe { with_free(((__local_LIST as *mut c_void) as *mut u8)) }

    unsafe { with_free(((__local_VECTOR as *mut c_void) as *mut u8)) }

}

pub fn test_tree() -> Unit {
    var __local_tree: tommy_tree_struct

    var __local_OBJ: *mut object_tree

    var __local_i: c_uint

    var __local_size: c_uint = ((250000 as c_uint))

    (__local_OBJ = (((unsafe { with_alloc(((((250000 as c_ulong) *% (sizeof[object_tree]() as c_ulong)) as c_ulong) as i64)) } as *mut c_void) as *mut object_tree)))

    unsafe { start(c"tree".ptr) }

    unsafe { tommy_tree_init((&raw mut __local_tree as *mut tommy_tree_struct), compare) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 250000: 1 else: 0) != 0) {
        ((unsafe __local_OBJ[__local_i]).value = ((__local_i as c_int)))

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 250000: 1 else: 0) != 0) {
        if ((if unsafe { tommy_tree_insert((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (unsafe __local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } != (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree)): 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    if ((if unsafe { tommy_tree_memory_usage((&raw mut __local_tree as *mut tommy_tree_struct)) } < 8000000: 1 else: 0) != 0) {
        abort()
    }

    if ((if unsafe { tommy_tree_count((&raw mut __local_tree as *mut tommy_tree_struct)) } != 250000: 1 else: 0) != 0) {
        abort()
    }

    (the_count = ((0 as c_uint)))

    unsafe { tommy_tree_foreach((&raw mut __local_tree as *mut tommy_tree_struct), count_callback) }

    if ((if the_count != 250000: 1 else: 0) != 0) {
        abort()
    }

    (the_count = ((0 as c_uint)))

    unsafe { tommy_tree_foreach_arg((&raw mut __local_tree as *mut tommy_tree_struct), count_arg_callback, ((&raw mut the_count as *mut c_uint) as *mut c_void)) }

    if ((if the_count != 250000: 1 else: 0) != 0) {
        abort()
    }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((250000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        if ((if unsafe { tommy_tree_search((&raw mut __local_tree as *mut tommy_tree_struct), (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } == 0: 1 else: 0) != 0) {
            abort()
        }

        if ((if unsafe { tommy_tree_search_compare((&raw mut __local_tree as *mut tommy_tree_struct), compare, (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } == 0: 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 250000: 1 else: 0) != 0) {
        var __local_EXTRA: object_tree

        (__local_EXTRA.value = ((__local_i as c_int)))

        if ((if unsafe { tommy_tree_insert((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (unsafe *(&raw const __local_EXTRA as *const object_tree)).node as *const tommy_node_struct) as *mut tommy_node_struct), ((&raw mut __local_EXTRA as *mut object_tree) as *mut c_void)) } == ((&raw mut __local_EXTRA as *mut object_tree)): 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((250000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        unsafe { tommy_tree_remove_existing((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (unsafe __local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((250000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        if ((if unsafe { tommy_tree_remove((&raw mut __local_tree as *mut tommy_tree_struct), (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } != 0: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((250000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        if ((if unsafe { tommy_tree_search((&raw mut __local_tree as *mut tommy_tree_struct), (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } != 0: 1 else: 0) != 0) {
            abort()
        }

        if ((if unsafe { tommy_tree_search_compare((&raw mut __local_tree as *mut tommy_tree_struct), compare, (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } != 0: 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((250000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        if ((if unsafe { tommy_tree_remove((&raw mut __local_tree as *mut tommy_tree_struct), (((&raw const (unsafe __local_OBJ[((((250000 as c_uint) / (2 as c_uint)) as c_uint) +% (__local_i as c_uint))]) as *const object_tree) as *mut object_tree) as *mut c_void)) } == 0: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 250000: 1 else: 0) != 0) {
        ((unsafe __local_OBJ[__local_i]).value = ((((250000 as c_uint) -% (__local_i as c_uint)) as c_int)))

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 250000: 1 else: 0) != 0) {
        if ((if unsafe { tommy_tree_insert((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (unsafe __local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } != (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree)): 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 250000: 1 else: 0) != 0) {
        unsafe { tommy_tree_remove_existing((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (unsafe __local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 250000: 1 else: 0) != 0) {
        ((unsafe __local_OBJ[__local_i]).value = ((tommy_inthash_u32(__local_i) as c_int)))

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 250000: 1 else: 0) != 0) {
        if ((if unsafe { tommy_tree_insert((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (unsafe __local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree) as *mut c_void)) } != (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_tree) as *mut object_tree)): 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 250000: 1 else: 0) != 0) {
        unsafe { tommy_tree_remove_existing((&raw mut __local_tree as *mut tommy_tree_struct), ((&raw const (unsafe __local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

        (__local_i = (__local_i +% 1))

    }


    stop()

}

pub fn test_array() -> Unit {
    var __local_array: tommy_array_struct

    var __local_i: c_ulong

    var __local_size: c_uint = ((50000000 as c_uint))

    unsafe { tommy_array_init((&raw mut __local_array as *mut tommy_array_struct)) }

    unsafe { tommy_array_grow((&raw mut __local_array as *mut tommy_array_struct), (0 as c_ulonglong)) }

    unsafe { start(c"array init".ptr) }

    (__local_i = ((0 as c_ulong)))

    while ((if __local_i < 50000000: 1 else: 0) != 0) {
        unsafe { tommy_array_grow((&raw mut __local_array as *mut tommy_array_struct), (((__local_i as c_ulong) +% (1 as c_ulong)) as c_ulonglong)) }

        if ((if unsafe { tommy_array_get((&raw mut __local_array as *mut tommy_array_struct), (__local_i as c_ulonglong)) } != 0: 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"array set".ptr) }

    (__local_i = ((0 as c_ulong)))

    while ((if __local_i < 50000000: 1 else: 0) != 0) {
        unsafe { tommy_array_set((&raw mut __local_array as *mut tommy_array_struct), (__local_i as c_ulonglong), (__local_i as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"array get".ptr) }

    (__local_i = ((0 as c_ulong)))

    while ((if __local_i < 50000000: 1 else: 0) != 0) {
        if ((if unsafe { tommy_array_get((&raw mut __local_array as *mut tommy_array_struct), (__local_i as c_ulonglong)) } != ((__local_i as *mut c_void)): 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    if ((if unsafe { tommy_array_memory_usage((&raw mut __local_array as *mut tommy_array_struct)) } < 400000000: 1 else: 0) != 0) {
        abort()
    }

    unsafe { tommy_array_done((&raw mut __local_array as *mut tommy_array_struct)) }

}

pub fn test_arrayof() -> Unit {
    var __local_arrayof: tommy_arrayof_struct

    var __local_i: c_uint

    var __local_size: c_uint = ((50000000 as c_uint))

    unsafe { tommy_arrayof_init((&raw mut __local_arrayof as *mut tommy_arrayof_struct), (4 as c_ulonglong)) }

    unsafe { tommy_arrayof_grow((&raw mut __local_arrayof as *mut tommy_arrayof_struct), (0 as c_ulonglong)) }

    unsafe { start(c"arrayof init".ptr) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 50000000: 1 else: 0) != 0) {
        unsafe { tommy_arrayof_grow((&raw mut __local_arrayof as *mut tommy_arrayof_struct), (((__local_i as c_uint) +% (1 as c_uint)) as c_ulonglong)) }

        var __local_ref: *mut c_uint = ((unsafe { tommy_arrayof_ref((&raw mut __local_arrayof as *mut tommy_arrayof_struct), (__local_i as c_ulonglong)) } as *mut c_uint))

        if ((if (unsafe *__local_ref) != 0: 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"arrayof set".ptr) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 50000000: 1 else: 0) != 0) {
        var __local_ref_1: *mut c_uint = ((unsafe { tommy_arrayof_ref((&raw mut __local_arrayof as *mut tommy_arrayof_struct), (__local_i as c_ulonglong)) } as *mut c_uint))

        ((unsafe *__local_ref_1) = __local_i)


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"arrayof get".ptr) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 50000000: 1 else: 0) != 0) {
        var __local_ref_2: *mut c_uint = ((unsafe { tommy_arrayof_ref((&raw mut __local_arrayof as *mut tommy_arrayof_struct), (__local_i as c_ulonglong)) } as *mut c_uint))

        if ((if (unsafe *__local_ref_2) != __local_i: 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    if ((if unsafe { tommy_arrayof_memory_usage((&raw mut __local_arrayof as *mut tommy_arrayof_struct)) } < 200000000: 1 else: 0) != 0) {
        abort()
    }

    unsafe { tommy_arrayof_done((&raw mut __local_arrayof as *mut tommy_arrayof_struct)) }

}

pub fn test_arrayblk() -> Unit {
    var __local_arrayblk: tommy_arrayblk_struct

    var __local_i: c_ulong

    var __local_size: c_uint = ((50000000 as c_uint))

    unsafe { tommy_arrayblk_init((&raw mut __local_arrayblk as *mut tommy_arrayblk_struct)) }

    unsafe { tommy_arrayblk_grow((&raw mut __local_arrayblk as *mut tommy_arrayblk_struct), (0 as c_ulonglong)) }

    unsafe { start(c"arrayblk init".ptr) }

    (__local_i = ((0 as c_ulong)))

    while ((if __local_i < 50000000: 1 else: 0) != 0) {
        unsafe { tommy_arrayblk_grow((&raw mut __local_arrayblk as *mut tommy_arrayblk_struct), (((__local_i as c_ulong) +% (1 as c_ulong)) as c_ulonglong)) }

        if ((if unsafe { tommy_arrayblk_get((&raw mut __local_arrayblk as *mut tommy_arrayblk_struct), (__local_i as c_ulonglong)) } != 0: 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"arrayblk set".ptr) }

    (__local_i = ((0 as c_ulong)))

    while ((if __local_i < 50000000: 1 else: 0) != 0) {
        unsafe { tommy_arrayblk_set((&raw mut __local_arrayblk as *mut tommy_arrayblk_struct), (__local_i as c_ulonglong), (__local_i as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"arrayblk get".ptr) }

    (__local_i = ((0 as c_ulong)))

    while ((if __local_i < 50000000: 1 else: 0) != 0) {
        if ((if unsafe { tommy_arrayblk_get((&raw mut __local_arrayblk as *mut tommy_arrayblk_struct), (__local_i as c_ulonglong)) } != ((__local_i as *mut c_void)): 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    if ((if unsafe { tommy_arrayblk_memory_usage((&raw mut __local_arrayblk as *mut tommy_arrayblk_struct)) } < 400000000: 1 else: 0) != 0) {
        abort()
    }

    unsafe { tommy_arrayblk_done((&raw mut __local_arrayblk as *mut tommy_arrayblk_struct)) }

}

pub fn test_arrayblkof() -> Unit {
    var __local_arrayblkof: tommy_arrayblkof_struct

    var __local_i: c_uint

    var __local_size: c_uint = ((50000000 as c_uint))

    unsafe { tommy_arrayblkof_init((&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct), (4 as c_ulonglong)) }

    unsafe { tommy_arrayblkof_grow((&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct), (0 as c_ulonglong)) }

    unsafe { start(c"arrayblkof init".ptr) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 50000000: 1 else: 0) != 0) {
        unsafe { tommy_arrayblkof_grow((&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct), (((__local_i as c_uint) +% (1 as c_uint)) as c_ulonglong)) }

        var __local_ref: *mut c_uint = ((unsafe { tommy_arrayblkof_ref((&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct), (__local_i as c_ulonglong)) } as *mut c_uint))

        if ((if (unsafe *__local_ref) != 0: 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"arrayblkof set".ptr) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 50000000: 1 else: 0) != 0) {
        var __local_ref_1: *mut c_uint = ((unsafe { tommy_arrayblkof_ref((&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct), (__local_i as c_ulonglong)) } as *mut c_uint))

        ((unsafe *__local_ref_1) = __local_i)


        (__local_i = (__local_i +% 1))

    }


    stop()

    unsafe { start(c"arrayblkof get".ptr) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 50000000: 1 else: 0) != 0) {
        var __local_ref_2: *mut c_uint = ((unsafe { tommy_arrayblkof_ref((&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct), (__local_i as c_ulonglong)) } as *mut c_uint))

        if ((if (unsafe *__local_ref_2) != __local_i: 1 else: 0) != 0) {
            abort()
        }


        (__local_i = (__local_i +% 1))

    }


    stop()

    if ((if unsafe { tommy_arrayblkof_memory_usage((&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct)) } < 200000000: 1 else: 0) != 0) {
        abort()
    }

    unsafe { tommy_arrayblkof_done((&raw mut __local_arrayblkof as *mut tommy_arrayblkof_struct)) }

}

pub fn test_hashtable() -> Unit {
    var __local_hashtable: tommy_hashtable_struct

    var __local_HASH: *mut object_hash

    var __local_i: c_uint

    var __local_j: c_uint

    var __local_n: c_uint


    var __local_limit: c_uint

    var __local_size: c_uint = ((1000000 as c_uint))

    var __local_module_: c_uint = ((250000 as c_uint))

    (__local_HASH = (((unsafe { with_alloc(((((1000000 as c_ulong) *% (sizeof[object_hash]() as c_ulong)) as c_ulong) as i64)) } as *mut c_void) as *mut object_hash)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 1000000: 1 else: 0) != 0) {
        ((unsafe __local_HASH[__local_i]).value = ((((__local_i as c_uint) % (250000 as c_uint)) as c_int)))

        (__local_i = (__local_i +% 1))

    }


    unsafe { tommy_hashtable_init((&raw mut __local_hashtable as *mut tommy_hashtable_struct), (1 as c_ulonglong)) }

    if ((if (unsafe *(&raw const __local_hashtable as *const tommy_hashtable_struct)).bucket_max == 1: 1 else: 0) != 0) {
        abort()
    }

    unsafe { tommy_hashtable_done((&raw mut __local_hashtable as *mut tommy_hashtable_struct)) }

    unsafe { start(c"hashtable stack".ptr) }

    (__local_limit = ((((5 as c_uint) *% (isqrt((1000000 as c_uint)) as c_uint)) as c_uint)))

    (__local_n = ((0 as c_uint)))

    while ((if __local_n <= __local_limit: 1 else: 0) != 0) {
        if ((if __local_n == __local_limit: 1 else: 0) != 0) {
            (__local_limit = ((1000000 as c_uint)))

            (__local_n = __local_limit)

        }

        unsafe { tommy_hashtable_init((&raw mut __local_hashtable as *mut tommy_hashtable_struct), (((__local_limit as c_uint) / (2 as c_uint)) as c_ulonglong)) }

        (__local_i = ((0 as c_uint)))

        while ((if __local_i < __local_n: 1 else: 0) != 0) {
            unsafe { tommy_hashtable_insert((&raw mut __local_hashtable as *mut tommy_hashtable_struct), ((&raw const (unsafe __local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((unsafe __local_HASH[__local_i]).value as c_ulonglong)) }

            (__local_i = (__local_i +% 1))

        }


        if ((if unsafe { tommy_hashtable_memory_usage((&raw mut __local_hashtable as *mut tommy_hashtable_struct)) } < ((__local_n as c_ulong) *% (sizeof[usize]() as c_ulong)): 1 else: 0) != 0) {
            abort()
        }

        if ((if unsafe { tommy_hashtable_count((&raw mut __local_hashtable as *mut tommy_hashtable_struct)) } != __local_n: 1 else: 0) != 0) {
            abort()
        }

        (the_count = ((0 as c_uint)))

        unsafe { tommy_hashtable_foreach((&raw mut __local_hashtable as *mut tommy_hashtable_struct), count_callback) }

        if ((if the_count != __local_n: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = ((0 as c_uint)))

        while ((if __local_i < ((__local_n as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
            unsafe { tommy_hashtable_remove_existing((&raw mut __local_hashtable as *mut tommy_hashtable_struct), ((&raw const (unsafe __local_HASH[((((__local_n as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

            (__local_i = (__local_i +% 1))

        }


        (__local_i = ((0 as c_uint)))

        while ((if __local_i < ((__local_n as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
            if ((if unsafe { tommy_hashtable_remove((&raw mut __local_hashtable as *mut tommy_hashtable_struct), search_callback, (((&raw const (unsafe __local_HASH[((((__local_n as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]) as *const object_hash) as *mut object_hash) as *const c_void), ((unsafe __local_HASH[((((__local_n as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]).value as c_ulonglong)) } != 0: 1 else: 0) != 0) {
                abort()
            }

            (__local_i = (__local_i +% 1))

        }


        (__local_i = ((0 as c_uint)))

        while ((if __local_i < ((__local_n as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
            if ((if unsafe { tommy_hashtable_remove((&raw mut __local_hashtable as *mut tommy_hashtable_struct), search_callback, (((&raw const (unsafe __local_HASH[((((((__local_n as c_uint) / (2 as c_uint)) as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]) as *const object_hash) as *mut object_hash) as *const c_void), ((unsafe __local_HASH[((((((__local_n as c_uint) / (2 as c_uint)) as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]).value as c_ulonglong)) } == 0: 1 else: 0) != 0) {
                abort()
            }

            (__local_i = (__local_i +% 1))

        }


        unsafe { tommy_hashtable_done((&raw mut __local_hashtable as *mut tommy_hashtable_struct)) }


        (__local_n = (__local_n +% 1))

    }


    stop()

    unsafe { start(c"hashtable queue".ptr) }

    (__local_limit = ((((isqrt((1000000 as c_uint)) as c_uint) / (16 as c_uint)) as c_uint)))

    (__local_n = ((0 as c_uint)))

    while ((if __local_n <= __local_limit: 1 else: 0) != 0) {
        if ((if __local_n == __local_limit: 1 else: 0) != 0) {
            (__local_limit = ((1000000 as c_uint)))

            (__local_n = __local_limit)

        }

        unsafe { tommy_hashtable_init((&raw mut __local_hashtable as *mut tommy_hashtable_struct), (((__local_limit as c_uint) / (2 as c_uint)) as c_ulonglong)) }

        (__local_j = ((0 as c_uint)))

        (__local_i = ((0 as c_uint)))


        while ((if __local_i < __local_n: 1 else: 0) != 0) {
            unsafe { tommy_hashtable_insert((&raw mut __local_hashtable as *mut tommy_hashtable_struct), ((&raw const (unsafe __local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((unsafe __local_HASH[__local_i]).value as c_ulonglong)) }

            (__local_i = (__local_i +% 1))

        }


        (the_count = ((0 as c_uint)))

        unsafe { tommy_hashtable_foreach_arg((&raw mut __local_hashtable as *mut tommy_hashtable_struct), count_arg_callback, ((&raw mut the_count as *mut c_uint) as *mut c_void)) }

        if ((if the_count != __local_n: 1 else: 0) != 0) {
            abort()
        }

        while ((if __local_i < 1000000: 1 else: 0) != 0) {
            unsafe { tommy_hashtable_insert((&raw mut __local_hashtable as *mut tommy_hashtable_struct), ((&raw const (unsafe __local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((unsafe __local_HASH[__local_i]).value as c_ulonglong)) }

            unsafe { tommy_hashtable_remove_existing((&raw mut __local_hashtable as *mut tommy_hashtable_struct), ((&raw const (unsafe __local_HASH[__local_j]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }


            (__local_i = (__local_i +% 1))

            (__local_j = (__local_j +% 1))


        }

        while ((if __local_j < 1000000: 1 else: 0) != 0) {
            if ((if unsafe { tommy_hashtable_remove((&raw mut __local_hashtable as *mut tommy_hashtable_struct), search_callback, (((&raw const (unsafe __local_HASH[__local_j]) as *const object_hash) as *mut object_hash) as *const c_void), ((unsafe __local_HASH[__local_j]).value as c_ulonglong)) } == 0: 1 else: 0) != 0) {
                abort()
            }

            (__local_j = (__local_j +% 1))

        }

        unsafe { tommy_hashtable_done((&raw mut __local_hashtable as *mut tommy_hashtable_struct)) }


        (__local_n = (__local_n +% 1))

    }


    stop()

}

pub fn test_hashdyn() -> Unit {
    var __local_hashdyn: tommy_hashdyn_struct

    var __local_HASH: *mut object_hash

    var __local_i: c_uint

    var __local_j: c_uint

    var __local_n: c_uint


    var __local_limit: c_uint

    var __local_size: c_uint = ((1000000 as c_uint))

    var __local_module_: c_uint = ((250000 as c_uint))

    (__local_HASH = (((unsafe { with_alloc(((((1000000 as c_ulong) *% (sizeof[object_hash]() as c_ulong)) as c_ulong) as i64)) } as *mut c_void) as *mut object_hash)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 1000000: 1 else: 0) != 0) {
        ((unsafe __local_HASH[__local_i]).value = ((((__local_i as c_uint) % (250000 as c_uint)) as c_int)))

        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"hashdyn stack".ptr) }

    (__local_limit = ((((5 as c_uint) *% (isqrt((1000000 as c_uint)) as c_uint)) as c_uint)))

    (__local_n = ((0 as c_uint)))

    while ((if __local_n <= __local_limit: 1 else: 0) != 0) {
        if ((if __local_n == __local_limit: 1 else: 0) != 0) {
            (__local_limit = ((1000000 as c_uint)))

            (__local_n = __local_limit)

        }

        unsafe { tommy_hashdyn_init((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct)) }

        (__local_i = ((0 as c_uint)))

        while ((if __local_i < __local_n: 1 else: 0) != 0) {
            unsafe { tommy_hashdyn_insert((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), ((&raw const (unsafe __local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((unsafe __local_HASH[__local_i]).value as c_ulonglong)) }

            (__local_i = (__local_i +% 1))

        }


        if ((if unsafe { tommy_hashdyn_memory_usage((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct)) } < ((__local_n as c_ulong) *% (sizeof[usize]() as c_ulong)): 1 else: 0) != 0) {
            abort()
        }

        if ((if unsafe { tommy_hashdyn_count((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct)) } != __local_n: 1 else: 0) != 0) {
            abort()
        }

        (the_count = ((0 as c_uint)))

        unsafe { tommy_hashdyn_foreach((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), count_callback) }

        if ((if the_count != __local_n: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = ((0 as c_uint)))

        while ((if __local_i < ((__local_n as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
            unsafe { tommy_hashdyn_remove_existing((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), ((&raw const (unsafe __local_HASH[((((__local_n as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

            (__local_i = (__local_i +% 1))

        }


        (__local_i = ((0 as c_uint)))

        while ((if __local_i < ((__local_n as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
            if ((if unsafe { tommy_hashdyn_remove((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), search_callback, (((&raw const (unsafe __local_HASH[((((__local_n as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]) as *const object_hash) as *mut object_hash) as *const c_void), ((unsafe __local_HASH[((((__local_n as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]).value as c_ulonglong)) } != 0: 1 else: 0) != 0) {
                abort()
            }

            (__local_i = (__local_i +% 1))

        }


        (__local_i = ((0 as c_uint)))

        while ((if __local_i < ((__local_n as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
            if ((if unsafe { tommy_hashdyn_remove((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), search_callback, (((&raw const (unsafe __local_HASH[((((((__local_n as c_uint) / (2 as c_uint)) as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]) as *const object_hash) as *mut object_hash) as *const c_void), ((unsafe __local_HASH[((((((__local_n as c_uint) / (2 as c_uint)) as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]).value as c_ulonglong)) } == 0: 1 else: 0) != 0) {
                abort()
            }

            (__local_i = (__local_i +% 1))

        }


        unsafe { tommy_hashdyn_done((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct)) }


        (__local_n = (__local_n +% 1))

    }


    stop()

    unsafe { start(c"hashdyn queue".ptr) }

    (__local_limit = ((((isqrt((1000000 as c_uint)) as c_uint) / (16 as c_uint)) as c_uint)))

    (__local_n = ((0 as c_uint)))

    while ((if __local_n <= __local_limit: 1 else: 0) != 0) {
        if ((if __local_n == __local_limit: 1 else: 0) != 0) {
            (__local_limit = ((1000000 as c_uint)))

            (__local_n = __local_limit)

        }

        unsafe { tommy_hashdyn_init((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct)) }

        (__local_j = ((0 as c_uint)))

        (__local_i = ((0 as c_uint)))


        while ((if __local_i < __local_n: 1 else: 0) != 0) {
            unsafe { tommy_hashdyn_insert((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), ((&raw const (unsafe __local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((unsafe __local_HASH[__local_i]).value as c_ulonglong)) }

            (__local_i = (__local_i +% 1))

        }


        (the_count = ((0 as c_uint)))

        unsafe { tommy_hashdyn_foreach_arg((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), count_arg_callback, ((&raw mut the_count as *mut c_uint) as *mut c_void)) }

        if ((if the_count != __local_n: 1 else: 0) != 0) {
            abort()
        }

        while ((if __local_i < 1000000: 1 else: 0) != 0) {
            unsafe { tommy_hashdyn_insert((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), ((&raw const (unsafe __local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((unsafe __local_HASH[__local_i]).value as c_ulonglong)) }

            unsafe { tommy_hashdyn_remove_existing((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), ((&raw const (unsafe __local_HASH[__local_j]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }


            (__local_i = (__local_i +% 1))

            (__local_j = (__local_j +% 1))


        }

        while ((if __local_j < 1000000: 1 else: 0) != 0) {
            if ((if unsafe { tommy_hashdyn_remove((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct), search_callback, (((&raw const (unsafe __local_HASH[__local_j]) as *const object_hash) as *mut object_hash) as *const c_void), ((unsafe __local_HASH[__local_j]).value as c_ulonglong)) } == 0: 1 else: 0) != 0) {
                abort()
            }

            (__local_j = (__local_j +% 1))

        }

        unsafe { tommy_hashdyn_done((&raw mut __local_hashdyn as *mut tommy_hashdyn_struct)) }


        (__local_n = (__local_n +% 1))

    }


    stop()

}

pub fn test_hashlin() -> Unit {
    var __local_hashlin: tommy_hashlin_struct

    var __local_HASH: *mut object_hash

    var __local_i: c_uint

    var __local_j: c_uint

    var __local_n: c_uint


    var __local_limit: c_uint

    var __local_size: c_uint = ((1000000 as c_uint))

    var __local_module_: c_uint = ((250000 as c_uint))

    var __local_bucket: *mut tommy_node_struct

    (__local_HASH = (((unsafe { with_alloc(((((1000000 as c_ulong) *% (sizeof[object_hash]() as c_ulong)) as c_ulong) as i64)) } as *mut c_void) as *mut object_hash)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 1000000: 1 else: 0) != 0) {
        ((unsafe __local_HASH[__local_i]).value = ((((__local_i as c_uint) % (250000 as c_uint)) as c_int)))

        (__local_i = (__local_i +% 1))

    }


    unsafe { tommy_hashlin_init((&raw mut __local_hashlin as *mut tommy_hashlin_struct)) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 1000000: 1 else: 0) != 0) {
        unsafe { tommy_hashlin_insert((&raw mut __local_hashlin as *mut tommy_hashlin_struct), ((&raw const (unsafe __local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((unsafe __local_HASH[__local_i]).value as c_ulonglong)) }

        (__local_i = (__local_i +% 1))

    }


    (__local_bucket = unsafe { tommy_hashlin_bucket((&raw mut __local_hashlin as *mut tommy_hashlin_struct), (249999 as c_ulonglong)) })

    if ((if __local_bucket == 0: 1 else: 0) != 0) {
        abort()
    }

    unsafe { tommy_hashlin_done((&raw mut __local_hashlin as *mut tommy_hashlin_struct)) }

    unsafe { start(c"hashlin stack".ptr) }

    (__local_limit = ((((5 as c_uint) *% (isqrt((1000000 as c_uint)) as c_uint)) as c_uint)))

    (__local_n = ((0 as c_uint)))

    while ((if __local_n <= __local_limit: 1 else: 0) != 0) {
        if ((if __local_n == __local_limit: 1 else: 0) != 0) {
            (__local_limit = ((1000000 as c_uint)))

            (__local_n = __local_limit)

        }

        unsafe { tommy_hashlin_init((&raw mut __local_hashlin as *mut tommy_hashlin_struct)) }

        (__local_i = ((0 as c_uint)))

        while ((if __local_i < __local_n: 1 else: 0) != 0) {
            unsafe { tommy_hashlin_insert((&raw mut __local_hashlin as *mut tommy_hashlin_struct), ((&raw const (unsafe __local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((unsafe __local_HASH[__local_i]).value as c_ulonglong)) }

            (__local_i = (__local_i +% 1))

        }


        if ((if unsafe { tommy_hashlin_memory_usage((&raw mut __local_hashlin as *mut tommy_hashlin_struct)) } < ((__local_n as c_ulong) *% (sizeof[usize]() as c_ulong)): 1 else: 0) != 0) {
            abort()
        }

        if ((if unsafe { tommy_hashlin_count((&raw mut __local_hashlin as *mut tommy_hashlin_struct)) } != __local_n: 1 else: 0) != 0) {
            abort()
        }

        (the_count = ((0 as c_uint)))

        unsafe { tommy_hashlin_foreach((&raw mut __local_hashlin as *mut tommy_hashlin_struct), count_callback) }

        if ((if the_count != __local_n: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = ((0 as c_uint)))

        while ((if __local_i < ((__local_n as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
            unsafe { tommy_hashlin_remove_existing((&raw mut __local_hashlin as *mut tommy_hashlin_struct), ((&raw const (unsafe __local_HASH[((((__local_n as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

            (__local_i = (__local_i +% 1))

        }


        (__local_i = ((0 as c_uint)))

        while ((if __local_i < ((__local_n as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
            if ((if unsafe { tommy_hashlin_remove((&raw mut __local_hashlin as *mut tommy_hashlin_struct), search_callback, (((&raw const (unsafe __local_HASH[((((__local_n as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]) as *const object_hash) as *mut object_hash) as *const c_void), ((unsafe __local_HASH[((((__local_n as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]).value as c_ulonglong)) } != 0: 1 else: 0) != 0) {
                abort()
            }

            (__local_i = (__local_i +% 1))

        }


        (__local_i = ((0 as c_uint)))

        while ((if __local_i < ((__local_n as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
            if ((if unsafe { tommy_hashlin_remove((&raw mut __local_hashlin as *mut tommy_hashlin_struct), search_callback, (((&raw const (unsafe __local_HASH[((((((__local_n as c_uint) / (2 as c_uint)) as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]) as *const object_hash) as *mut object_hash) as *const c_void), ((unsafe __local_HASH[((((((__local_n as c_uint) / (2 as c_uint)) as c_uint) -% (__local_i as c_uint)) as c_uint) -% (1 as c_uint))]).value as c_ulonglong)) } == 0: 1 else: 0) != 0) {
                abort()
            }

            (__local_i = (__local_i +% 1))

        }


        unsafe { tommy_hashlin_done((&raw mut __local_hashlin as *mut tommy_hashlin_struct)) }


        (__local_n = (__local_n +% 1))

    }


    stop()

    unsafe { start(c"hashlin queue".ptr) }

    (__local_limit = ((((isqrt((1000000 as c_uint)) as c_uint) / (16 as c_uint)) as c_uint)))

    (__local_n = ((0 as c_uint)))

    while ((if __local_n <= __local_limit: 1 else: 0) != 0) {
        if ((if __local_n == __local_limit: 1 else: 0) != 0) {
            (__local_limit = ((1000000 as c_uint)))

            (__local_n = __local_limit)

        }

        unsafe { tommy_hashlin_init((&raw mut __local_hashlin as *mut tommy_hashlin_struct)) }

        (__local_j = ((0 as c_uint)))

        (__local_i = ((0 as c_uint)))


        while ((if __local_i < __local_n: 1 else: 0) != 0) {
            unsafe { tommy_hashlin_insert((&raw mut __local_hashlin as *mut tommy_hashlin_struct), ((&raw const (unsafe __local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((unsafe __local_HASH[__local_i]).value as c_ulonglong)) }

            (__local_i = (__local_i +% 1))

        }


        (the_count = ((0 as c_uint)))

        unsafe { tommy_hashlin_foreach_arg((&raw mut __local_hashlin as *mut tommy_hashlin_struct), count_arg_callback, ((&raw mut the_count as *mut c_uint) as *mut c_void)) }

        if ((if the_count != __local_n: 1 else: 0) != 0) {
            abort()
        }

        while ((if __local_i < 1000000: 1 else: 0) != 0) {
            unsafe { tommy_hashlin_insert((&raw mut __local_hashlin as *mut tommy_hashlin_struct), ((&raw const (unsafe __local_HASH[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_HASH[__local_i]) as *const object_hash) as *mut object_hash) as *mut c_void), ((unsafe __local_HASH[__local_i]).value as c_ulonglong)) }

            unsafe { tommy_hashlin_remove_existing((&raw mut __local_hashlin as *mut tommy_hashlin_struct), ((&raw const (unsafe __local_HASH[__local_j]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }


            (__local_i = (__local_i +% 1))

            (__local_j = (__local_j +% 1))


        }

        while ((if __local_j < 1000000: 1 else: 0) != 0) {
            if ((if unsafe { tommy_hashlin_remove((&raw mut __local_hashlin as *mut tommy_hashlin_struct), search_callback, (((&raw const (unsafe __local_HASH[__local_j]) as *const object_hash) as *mut object_hash) as *const c_void), ((unsafe __local_HASH[__local_j]).value as c_ulonglong)) } == 0: 1 else: 0) != 0) {
                abort()
            }

            (__local_j = (__local_j +% 1))

        }

        unsafe { tommy_hashlin_done((&raw mut __local_hashlin as *mut tommy_hashlin_struct)) }


        (__local_n = (__local_n +% 1))

    }


    stop()

}

pub fn test_trie() -> Unit {
    var __local_trie: tommy_trie_struct

    var __local_alloc: tommy_allocator_struct

    var __local_OBJ: *mut object_trie

    var __local_DUP: [2]object_trie

    var __local_i: c_uint

    var __local_size: c_uint = ((4000000 as c_uint))

    (__local_OBJ = (((unsafe { with_alloc(((((4000000 as c_ulong) *% (sizeof[object_trie]() as c_ulong)) as c_ulong) as i64)) } as *mut c_void) as *mut object_trie)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 4000000: 1 else: 0) != 0) {
        ((unsafe __local_OBJ[__local_i]).value = ((__local_i as c_int)))

        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"trie".ptr) }

    unsafe { tommy_allocator_init((&raw mut __local_alloc as *mut tommy_allocator_struct), (64 as c_ulonglong), (64 as c_ulonglong)) }

    unsafe { tommy_trie_init((&raw mut __local_trie as *mut tommy_trie_struct), (&raw mut __local_alloc as *mut tommy_allocator_struct)) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 4000000: 1 else: 0) != 0) {
        unsafe { tommy_trie_insert((&raw mut __local_trie as *mut tommy_trie_struct), ((&raw const (unsafe __local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_trie) as *mut object_trie) as *mut c_void), ((unsafe __local_OBJ[__local_i]).value as c_ulonglong)) }

        (__local_i = (__local_i +% 1))

    }


    if ((if unsafe { tommy_trie_memory_usage((&raw mut __local_trie as *mut tommy_trie_struct)) } < 128000000: 1 else: 0) != 0) {
        abort()
    }

    if ((if unsafe { tommy_allocator_memory_usage((&raw mut __local_alloc as *mut tommy_allocator_struct)) } < (((unsafe *(&raw const __local_trie as *const tommy_trie_struct)).node_count as c_ulonglong) *% (64 as c_ulonglong)): 1 else: 0) != 0) {
        abort()
    }

    if ((if unsafe { tommy_trie_count((&raw mut __local_trie as *mut tommy_trie_struct)) } != 4000000: 1 else: 0) != 0) {
        abort()
    }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 2: 1 else: 0) != 0) {
        (__local_DUP[__local_i].value = ((0 as c_int)))

        unsafe { tommy_trie_insert((&raw mut __local_trie as *mut tommy_trie_struct), ((&raw const __local_DUP[__local_i].node as *const tommy_node_struct) as *mut tommy_node_struct), (((&raw const __local_DUP[__local_i] as *const object_trie) as *mut object_trie) as *mut c_void), (__local_DUP[__local_i].value as c_ulonglong)) }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((4000000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        if ((if unsafe { tommy_trie_search((&raw mut __local_trie as *mut tommy_trie_struct), ((unsafe __local_OBJ[__local_i]).value as c_ulonglong)) } == 0: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    unsafe { tommy_trie_remove_existing((&raw mut __local_trie as *mut tommy_trie_struct), ((&raw const __local_DUP[0].node as *const tommy_node_struct) as *mut tommy_node_struct)) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((4000000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        unsafe { tommy_trie_remove_existing((&raw mut __local_trie as *mut tommy_trie_struct), ((&raw const (unsafe __local_OBJ[__local_i]).node as *const tommy_node_struct) as *mut tommy_node_struct)) }

        (__local_i = (__local_i +% 1))

    }


    if ((if unsafe { tommy_trie_remove((&raw mut __local_trie as *mut tommy_trie_struct), (1 as c_ulonglong)) } != 0: 1 else: 0) != 0) {
        abort()
    }

    if ((if unsafe { tommy_trie_search((&raw mut __local_trie as *mut tommy_trie_struct), (1 as c_ulonglong)) } != 0: 1 else: 0) != 0) {
        abort()
    }

    unsafe { tommy_trie_remove_existing((&raw mut __local_trie as *mut tommy_trie_struct), ((&raw const __local_DUP[1].node as *const tommy_node_struct) as *mut tommy_node_struct)) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((4000000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        if ((if unsafe { tommy_trie_remove((&raw mut __local_trie as *mut tommy_trie_struct), ((unsafe __local_OBJ[__local_i]).value as c_ulonglong)) } != 0: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((4000000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        if ((if unsafe { tommy_trie_search((&raw mut __local_trie as *mut tommy_trie_struct), ((unsafe __local_OBJ[__local_i]).value as c_ulonglong)) } != 0: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((4000000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        if ((if unsafe { tommy_trie_remove((&raw mut __local_trie as *mut tommy_trie_struct), ((unsafe __local_OBJ[((((4000000 as c_uint) / (2 as c_uint)) as c_uint) +% (__local_i as c_uint))]).value as c_ulonglong)) } == 0: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    unsafe { tommy_allocator_done((&raw mut __local_alloc as *mut tommy_allocator_struct)) }

    stop()

}

pub fn test_trie_inplace() -> Unit {
    var __local_trie_inplace: tommy_trie_inplace_struct

    var __local_OBJ: *mut object_trie_inplace

    var __local_DUP: [2]object_trie_inplace

    var __local_i: c_uint

    var __local_size: c_uint = ((4000000 as c_uint))

    (__local_OBJ = (((unsafe { with_alloc(((((4000000 as c_ulong) *% (sizeof[object_trie_inplace]() as c_ulong)) as c_ulong) as i64)) } as *mut c_void) as *mut object_trie_inplace)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 4000000: 1 else: 0) != 0) {
        ((unsafe __local_OBJ[__local_i]).value = ((__local_i as c_int)))

        (__local_i = (__local_i +% 1))

    }


    unsafe { start(c"trie_inplace".ptr) }

    unsafe { tommy_trie_inplace_init((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct)) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 4000000: 1 else: 0) != 0) {
        unsafe { tommy_trie_inplace_insert((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((&raw const (unsafe __local_OBJ[__local_i]).node as *const tommy_trie_inplace_node_struct) as *mut tommy_trie_inplace_node_struct), (((&raw const (unsafe __local_OBJ[__local_i]) as *const object_trie_inplace) as *mut object_trie_inplace) as *mut c_void), ((unsafe __local_OBJ[__local_i]).value as c_ulonglong)) }

        (__local_i = (__local_i +% 1))

    }


    if ((if unsafe { tommy_trie_inplace_memory_usage((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct)) } < 256000000: 1 else: 0) != 0) {
        abort()
    }

    if ((if unsafe { tommy_trie_inplace_count((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct)) } != 4000000: 1 else: 0) != 0) {
        abort()
    }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 2: 1 else: 0) != 0) {
        (__local_DUP[__local_i].value = ((0 as c_int)))

        unsafe { tommy_trie_inplace_insert((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((&raw const __local_DUP[__local_i].node as *const tommy_trie_inplace_node_struct) as *mut tommy_trie_inplace_node_struct), (((&raw const __local_DUP[__local_i] as *const object_trie_inplace) as *mut object_trie_inplace) as *mut c_void), (__local_DUP[__local_i].value as c_ulonglong)) }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((4000000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        if ((if unsafe { tommy_trie_inplace_search((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((unsafe __local_OBJ[__local_i]).value as c_ulonglong)) } == 0: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    unsafe { tommy_trie_inplace_remove_existing((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((&raw const __local_DUP[0].node as *const tommy_trie_inplace_node_struct) as *mut tommy_trie_inplace_node_struct)) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((4000000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        unsafe { tommy_trie_inplace_remove_existing((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((&raw const (unsafe __local_OBJ[__local_i]).node as *const tommy_trie_inplace_node_struct) as *mut tommy_trie_inplace_node_struct)) }

        (__local_i = (__local_i +% 1))

    }


    unsafe { tommy_trie_inplace_remove_existing((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((&raw const __local_DUP[1].node as *const tommy_trie_inplace_node_struct) as *mut tommy_trie_inplace_node_struct)) }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((4000000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        if ((if unsafe { tommy_trie_inplace_remove((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((unsafe __local_OBJ[__local_i]).value as c_ulonglong)) } != 0: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((4000000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        if ((if unsafe { tommy_trie_inplace_search((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((unsafe __local_OBJ[__local_i]).value as c_ulonglong)) } != 0: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((4000000 as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        if ((if unsafe { tommy_trie_inplace_remove((&raw mut __local_trie_inplace as *mut tommy_trie_inplace_struct), ((unsafe __local_OBJ[((((4000000 as c_uint) / (2 as c_uint)) as c_uint) +% (__local_i as c_uint))]).value as c_ulonglong)) } == 0: 1 else: 0) != 0) {
            abort()
        }

        (__local_i = (__local_i +% 1))

    }


    stop()

}

pub fn main(...) -> c_int {
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

    return 0

}

var the_cache: [16777216]u8 = [0 as u8; 16777216]
var the_str: *const i8 = null
var the_start: c_ulonglong = 0
var the_count: c_uint = 0
