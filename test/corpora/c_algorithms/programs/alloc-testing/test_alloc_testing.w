// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.framework
use std.libc

fn test_malloc_free() -> Unit {
    var __local_block: *mut c_void

    var __local_block2: *mut c_void

    var __local_block3: *mut c_void

    var __local_block4: *mut c_void


    var __local_ptr: *mut u8

    var __local_i: c_int

    if ((((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (38 as c_int), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    (__local_block = alloc_test_malloc((1024 as c_ulong)))

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (42 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 1024: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (43 as c_int), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    (__local_ptr = ((__local_block as *mut u8)))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 1024: 1 else: 0) != 0) {
        if ((((if not ((if (unsafe __local_ptr[__local_i]) != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (49 as c_int), c"ptr[i] != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { alloc_test_free(__local_block) }

    if ((((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (55 as c_int), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    alloc_test_set_limit((3 as c_int))

    (__local_block = alloc_test_malloc((1024 as c_ulong)))

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (61 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    (__local_block2 = alloc_test_malloc((1024 as c_ulong)))

    if ((((if not ((if __local_block2 != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (63 as c_int), c"block2 != NULL".ptr)
    } else {
        0
    }

    (__local_block3 = alloc_test_malloc((1024 as c_ulong)))

    if ((((if not ((if __local_block3 != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (65 as c_int), c"block3 != NULL".ptr)
    } else {
        0
    }

    (__local_block4 = alloc_test_malloc((1024 as c_ulong)))

    if ((((if not ((if __local_block4 == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (67 as c_int), c"block4 == NULL".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

    unsafe { alloc_test_free(__local_block2) }

    unsafe { alloc_test_free(__local_block3) }

    unsafe { alloc_test_free(__local_block4) }

}

fn test_realloc() -> Unit {
    var __local_block: *mut c_void

    var __local_block2: *mut c_void

    (__local_block2 = alloc_test_malloc((1024 as c_ulong)))

    (__local_block = alloc_test_malloc((1024 as c_ulong)))

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (85 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 2048: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (86 as c_int), c"alloc_test_get_allocated() == 1024 + 1024".ptr)
    } else {
        0
    }

    (__local_block = unsafe { alloc_test_realloc(__local_block, (2048 as c_ulong)) })

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (90 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 3072: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (92 as c_int), c"alloc_test_get_allocated() == 2048 + 1024".ptr)
    } else {
        0
    }

    (__local_block = unsafe { alloc_test_realloc(__local_block, (1500 as c_ulong)) })

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (96 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 2524: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (98 as c_int), c"alloc_test_get_allocated() == 1500 + 1024".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

    if ((((if not ((if alloc_test_get_allocated() == 1024: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (102 as c_int), c"alloc_test_get_allocated() == 0 + 1024".ptr)
    } else {
        0
    }

    (__local_block = unsafe { alloc_test_realloc(null, (1024 as c_ulong)) })

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (107 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 2048: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (109 as c_int), c"alloc_test_get_allocated() == 1024 + 1024".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

    unsafe { alloc_test_free(__local_block2) }

    if ((((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (114 as c_int), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    (__local_block = alloc_test_malloc((512 as c_ulong)))

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (118 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 512: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (119 as c_int), c"alloc_test_get_allocated() == 512".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as c_int))

    (__local_block = unsafe { alloc_test_realloc(__local_block, (1024 as c_ulong)) })

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (124 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 1024: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (125 as c_int), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { alloc_test_realloc(__local_block, (2048 as c_ulong)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (127 as c_int), c"realloc(block, 2048) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 1024: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (128 as c_int), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

    if ((((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (131 as c_int), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as c_int))

    (__local_block = unsafe { alloc_test_realloc(null, (1024 as c_ulong)) })

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (137 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 1024: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (138 as c_int), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { alloc_test_realloc(null, (1024 as c_ulong)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (140 as c_int), c"realloc(NULL, 1024) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 1024: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (141 as c_int), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

}

fn test_calloc() -> Unit {
    var __local_block: *mut u8

    var __local_i: c_int

    if ((((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (151 as c_int), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    (__local_block = ((alloc_test_calloc((16 as c_ulong), (64 as c_ulong)) as *mut u8)))

    if ((((if not ((if alloc_test_get_allocated() == 1024: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (156 as c_int), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (158 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 1024: 1 else: 0) != 0) {
        if ((((if not ((if (unsafe __local_block[__local_i]) == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (162 as c_int), c"block[i] == 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { alloc_test_free((__local_block as *mut c_void)) }

    if ((((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (167 as c_int), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as c_int))

    (__local_block = ((alloc_test_calloc((1024 as c_ulong), (1 as c_ulong)) as *mut u8)))

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (173 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 1024: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (174 as c_int), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_calloc((1024 as c_ulong), (1 as c_ulong)) == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (176 as c_int), c"calloc(1024, 1) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 1024: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (177 as c_int), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free((__local_block as *mut c_void)) }

}

fn test_strdup() -> Unit {
    var __local_str: *mut c_char

    if ((((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (186 as c_int), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    (__local_str = ((unsafe { alloc_test_strdup(c"hello world".ptr) } as *mut c_char)))

    if ((((if not ((if __local_str != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (191 as c_int), c"str != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if strcmp((__local_str as *const i8), c"hello world".ptr) == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (192 as c_int), c"strcmp(str, \"hello world\") == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 12: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (194 as c_int), c"alloc_test_get_allocated() == 12".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free((__local_str as *mut c_void)) }

    if ((((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (198 as c_int), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as c_int))

    (__local_str = ((unsafe { alloc_test_strdup(c"hello world".ptr) } as *mut c_char)))

    if ((((if not ((if __local_str != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (204 as c_int), c"str != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 12: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (205 as c_int), c"alloc_test_get_allocated() == 12".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { alloc_test_strdup(c"hello world".ptr) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (207 as c_int), c"strdup(\"hello world\") == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 12: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (208 as c_int), c"alloc_test_get_allocated() == 12".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free((__local_str as *mut c_void)) }

}

fn test_limits() -> Unit {
    var __local_block: *mut c_void

    (__local_block = alloc_test_malloc((2048 as c_ulong)))

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_limits".ptr, c"test-alloc-testing.c".ptr, (219 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

    alloc_test_set_limit((1 as c_int))

    (__local_block = alloc_test_malloc((1024 as c_ulong)))

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_limits".ptr, c"test-alloc-testing.c".ptr, (225 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_malloc((1024 as c_ulong)) == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_limits".ptr, c"test-alloc-testing.c".ptr, (226 as c_int), c"malloc(1024) == NULL".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

    alloc_test_set_limit((-1 as c_int))

    (__local_block = alloc_test_malloc((1024 as c_ulong)))

    if ((((if not ((if __local_block != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_limits".ptr, c"test-alloc-testing.c".ptr, (232 as c_int), c"block != NULL".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [6]extern "C" fn() -> Unit = [test_malloc_free, test_realloc, test_calloc, test_strdup, test_limits, null]
