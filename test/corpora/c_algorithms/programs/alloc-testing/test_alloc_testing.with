// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.engines.c_algorithms_testing.framework
use std.libc
use std.option
use std.collections

fn test_malloc_free() {
    var __local_block: *mut c_void

    var __local_block2: *mut c_void

    var __local_block3: *mut c_void

    var __local_block4: *mut c_void


    var __local_ptr: *mut u8

    var __local_i: i32

    if ((if not (alloc_test_get_allocated() == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (38 as i32), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    (__local_block = alloc_test_malloc((1024 as u64)))

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (42 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 1024): 1 else: 0) as i64) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (43 as i32), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    (__local_ptr = ((__local_block as *mut u8)))

    (__local_i = ((0 as i32)))

    while (__local_i < 1024) {
        if ((if not ((unsafe __local_ptr[__local_i]) != 0): 1 else: 0) as i64) {
            __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (49 as i32), c"ptr[i] != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { alloc_test_free(__local_block) }

    if ((if not (alloc_test_get_allocated() == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (55 as i32), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    alloc_test_set_limit((3 as i32))

    (__local_block = alloc_test_malloc((1024 as u64)))

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (61 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    (__local_block2 = alloc_test_malloc((1024 as u64)))

    if ((if not (__local_block2 != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (63 as i32), c"block2 != NULL".ptr)
    } else {
        0
    }

    (__local_block3 = alloc_test_malloc((1024 as u64)))

    if ((if not (__local_block3 != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (65 as i32), c"block3 != NULL".ptr)
    } else {
        0
    }

    (__local_block4 = alloc_test_malloc((1024 as u64)))

    if ((if not (__local_block4 == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_malloc_free".ptr, c"test-alloc-testing.c".ptr, (67 as i32), c"block4 == NULL".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

    unsafe { alloc_test_free(__local_block2) }

    unsafe { alloc_test_free(__local_block3) }

    unsafe { alloc_test_free(__local_block4) }

}

fn test_realloc() {
    var __local_block: *mut c_void

    var __local_block2: *mut c_void

    (__local_block2 = alloc_test_malloc((1024 as u64)))

    (__local_block = alloc_test_malloc((1024 as u64)))

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (85 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 2048): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (86 as i32), c"alloc_test_get_allocated() == 1024 + 1024".ptr)
    } else {
        0
    }

    (__local_block = unsafe { alloc_test_realloc(__local_block, (2048 as u64)) })

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (90 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 3072): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (92 as i32), c"alloc_test_get_allocated() == 2048 + 1024".ptr)
    } else {
        0
    }

    (__local_block = unsafe { alloc_test_realloc(__local_block, (1500 as u64)) })

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (96 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 2524): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (98 as i32), c"alloc_test_get_allocated() == 1500 + 1024".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

    if ((if not (alloc_test_get_allocated() == 1024): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (102 as i32), c"alloc_test_get_allocated() == 0 + 1024".ptr)
    } else {
        0
    }

    (__local_block = unsafe { alloc_test_realloc(null, (1024 as u64)) })

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (107 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 2048): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (109 as i32), c"alloc_test_get_allocated() == 1024 + 1024".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

    unsafe { alloc_test_free(__local_block2) }

    if ((if not (alloc_test_get_allocated() == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (114 as i32), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    (__local_block = alloc_test_malloc((512 as u64)))

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (118 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 512): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (119 as i32), c"alloc_test_get_allocated() == 512".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as i32))

    (__local_block = unsafe { alloc_test_realloc(__local_block, (1024 as u64)) })

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (124 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 1024): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (125 as i32), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    if ((if not (unsafe { alloc_test_realloc(__local_block, (2048 as u64)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (127 as i32), c"realloc(block, 2048) == NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 1024): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (128 as i32), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

    if ((if not (alloc_test_get_allocated() == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (131 as i32), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as i32))

    (__local_block = unsafe { alloc_test_realloc(null, (1024 as u64)) })

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (137 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 1024): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (138 as i32), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    if ((if not (unsafe { alloc_test_realloc(null, (1024 as u64)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (140 as i32), c"realloc(NULL, 1024) == NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 1024): 1 else: 0) as i64) {
        __assert_rtn(c"test_realloc".ptr, c"test-alloc-testing.c".ptr, (141 as i32), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

}

fn test_calloc() {
    var __local_block: *mut u8

    var __local_i: i32

    if ((if not (alloc_test_get_allocated() == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (151 as i32), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    (__local_block = ((alloc_test_calloc((16 as u64), (64 as u64)) as *mut u8)))

    if ((if not (alloc_test_get_allocated() == 1024): 1 else: 0) as i64) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (156 as i32), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (158 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    (__local_i = ((0 as i32)))

    while (__local_i < 1024) {
        if ((if not ((unsafe __local_block[__local_i]) == 0): 1 else: 0) as i64) {
            __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (162 as i32), c"block[i] == 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { alloc_test_free((__local_block as *mut c_void)) }

    if ((if not (alloc_test_get_allocated() == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (167 as i32), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as i32))

    (__local_block = ((alloc_test_calloc((1024 as u64), (1 as u64)) as *mut u8)))

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (173 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 1024): 1 else: 0) as i64) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (174 as i32), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_calloc((1024 as u64), (1 as u64)) == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (176 as i32), c"calloc(1024, 1) == NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 1024): 1 else: 0) as i64) {
        __assert_rtn(c"test_calloc".ptr, c"test-alloc-testing.c".ptr, (177 as i32), c"alloc_test_get_allocated() == 1024".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free((__local_block as *mut c_void)) }

}

fn test_strdup() {
    var __local_str: *mut c_char

    if ((if not (alloc_test_get_allocated() == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (186 as i32), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    (__local_str = unsafe { alloc_test_strdup(c"hello world".ptr) })

    if ((if not (__local_str != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (191 as i32), c"str != NULL".ptr)
    } else {
        0
    }

    if ((if not (strcmp((__local_str as *const c_char), c"hello world".ptr) == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (192 as i32), c"strcmp(str, \"hello world\") == 0".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 12): 1 else: 0) as i64) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (194 as i32), c"alloc_test_get_allocated() == 12".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free((__local_str as *mut c_void)) }

    if ((if not (alloc_test_get_allocated() == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (198 as i32), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as i32))

    (__local_str = unsafe { alloc_test_strdup(c"hello world".ptr) })

    if ((if not (__local_str != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (204 as i32), c"str != NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 12): 1 else: 0) as i64) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (205 as i32), c"alloc_test_get_allocated() == 12".ptr)
    } else {
        0
    }

    if ((if not (unsafe { alloc_test_strdup(c"hello world".ptr) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (207 as i32), c"strdup(\"hello world\") == NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_get_allocated() == 12): 1 else: 0) as i64) {
        __assert_rtn(c"test_strdup".ptr, c"test-alloc-testing.c".ptr, (208 as i32), c"alloc_test_get_allocated() == 12".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free((__local_str as *mut c_void)) }

}

fn test_limits() {
    var __local_block: *mut c_void

    (__local_block = alloc_test_malloc((2048 as u64)))

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_limits".ptr, c"test-alloc-testing.c".ptr, (219 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

    alloc_test_set_limit((1 as i32))

    (__local_block = alloc_test_malloc((1024 as u64)))

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_limits".ptr, c"test-alloc-testing.c".ptr, (225 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    if ((if not (alloc_test_malloc((1024 as u64)) == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_limits".ptr, c"test-alloc-testing.c".ptr, (226 as i32), c"malloc(1024) == NULL".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

    alloc_test_set_limit((-1 as i32))

    (__local_block = alloc_test_malloc((1024 as u64)))

    if ((if not (__local_block != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_limits".ptr, c"test-alloc-testing.c".ptr, (232 as i32), c"block != NULL".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free(__local_block) }

}

// contract: unproved:1:read only
pub unsafe fn main(__param_argc: i32, __param_argv: *mut *mut c_char) -> i32 writes allocation_limit {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

let tests: List[Option[extern "C" fn() -> Unit]] = [Some(test_malloc_free), Some(test_realloc), Some(test_calloc), Some(test_strdup), Some(test_limits), null]
