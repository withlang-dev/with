// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.framework
use std.calg_testing.queue
use std.libc

pub fn generate_queue() -> *mut _Queue {
    var __local_queue: *mut _Queue

    var __local_i: c_int

    (__local_queue = queue_new())

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 1000: 1 else: 0) != 0) {
        unsafe { queue_push_head(__local_queue, ((&raw mut variable1 as *mut c_int) as *mut c_void)) }

        unsafe { queue_push_head(__local_queue, ((&raw mut variable2 as *mut c_int) as *mut c_void)) }

        unsafe { queue_push_head(__local_queue, ((&raw mut variable3 as *mut c_int) as *mut c_void)) }

        unsafe { queue_push_head(__local_queue, ((&raw mut variable4 as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    return __local_queue

}

pub fn test_queue_new_free() -> Unit {
    var __local_i: c_int

    var __local_queue: *mut _Queue

    (__local_queue = queue_new())

    unsafe { queue_free(__local_queue) }

    (__local_queue = queue_new())

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 1000: 1 else: 0) != 0) {
        unsafe { queue_push_head(__local_queue, ((&raw mut variable1 as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    unsafe { queue_free(__local_queue) }

    alloc_test_set_limit((0 as c_int))

    (__local_queue = queue_new())

    if ((((if not ((if __local_queue == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_new_free".ptr, c"test-queue.c".ptr, (73 as c_int), c"queue == NULL".ptr)
    } else {
        0
    }

}

pub fn test_queue_push_head() -> Unit {
    var __local_queue: *mut _Queue

    var __local_i: c_int

    (__local_queue = queue_new())

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 1000: 1 else: 0) != 0) {
        unsafe { queue_push_head(__local_queue, ((&raw mut variable1 as *mut c_int) as *mut c_void)) }

        unsafe { queue_push_head(__local_queue, ((&raw mut variable2 as *mut c_int) as *mut c_void)) }

        unsafe { queue_push_head(__local_queue, ((&raw mut variable3 as *mut c_int) as *mut c_void)) }

        unsafe { queue_push_head(__local_queue, ((&raw mut variable4 as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    if ((((if not ((if not (unsafe { queue_is_empty(__local_queue) } != 0): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_head".ptr, c"test-queue.c".ptr, (91 as c_int), c"!queue_is_empty(queue)".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_head".ptr, c"test-queue.c".ptr, (94 as c_int), c"queue_pop_tail(queue) == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_head".ptr, c"test-queue.c".ptr, (95 as c_int), c"queue_pop_tail(queue) == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_head".ptr, c"test-queue.c".ptr, (96 as c_int), c"queue_pop_tail(queue) == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_head".ptr, c"test-queue.c".ptr, (97 as c_int), c"queue_pop_tail(queue) == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_head".ptr, c"test-queue.c".ptr, (100 as c_int), c"queue_pop_head(queue) == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_head".ptr, c"test-queue.c".ptr, (101 as c_int), c"queue_pop_head(queue) == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_head".ptr, c"test-queue.c".ptr, (102 as c_int), c"queue_pop_head(queue) == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_head".ptr, c"test-queue.c".ptr, (103 as c_int), c"queue_pop_head(queue) == &variable1".ptr)
    } else {
        0
    }

    unsafe { queue_free(__local_queue) }

    (__local_queue = queue_new())

    alloc_test_set_limit((0 as c_int))

    if ((((if not ((if not (unsafe { queue_push_head(__local_queue, ((&raw mut variable1 as *mut c_int) as *mut c_void)) } != 0): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_head".ptr, c"test-queue.c".ptr, (111 as c_int), c"!queue_push_head(queue, &variable1)".ptr)
    } else {
        0
    }

    unsafe { queue_free(__local_queue) }

}

pub fn test_queue_pop_head() -> Unit {
    var __local_queue: *mut _Queue

    (__local_queue = queue_new())

    if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_pop_head".ptr, c"test-queue.c".ptr, (123 as c_int), c"queue_pop_head(queue) == NULL".ptr)
    } else {
        0
    }

    unsafe { queue_free(__local_queue) }

    (__local_queue = generate_queue())

    while ((if not (unsafe { queue_is_empty(__local_queue) } != 0): 1 else: 0) != 0) {
        if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_pop_head".ptr, c"test-queue.c".ptr, (131 as c_int), c"queue_pop_head(queue) == &variable4".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_pop_head".ptr, c"test-queue.c".ptr, (132 as c_int), c"queue_pop_head(queue) == &variable3".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_pop_head".ptr, c"test-queue.c".ptr, (133 as c_int), c"queue_pop_head(queue) == &variable2".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_pop_head".ptr, c"test-queue.c".ptr, (134 as c_int), c"queue_pop_head(queue) == &variable1".ptr)
        } else {
            0
        }

    }

    if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_pop_head".ptr, c"test-queue.c".ptr, (137 as c_int), c"queue_pop_head(queue) == NULL".ptr)
    } else {
        0
    }

    unsafe { queue_free(__local_queue) }

}

pub fn test_queue_peek_head() -> Unit {
    var __local_queue: *mut _Queue

    (__local_queue = queue_new())

    if ((((if not ((if unsafe { queue_peek_head(__local_queue) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_peek_head".ptr, c"test-queue.c".ptr, (149 as c_int), c"queue_peek_head(queue) == NULL".ptr)
    } else {
        0
    }

    unsafe { queue_free(__local_queue) }

    (__local_queue = generate_queue())

    while ((if not (unsafe { queue_is_empty(__local_queue) } != 0): 1 else: 0) != 0) {
        if ((((if not ((if unsafe { queue_peek_head(__local_queue) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_head".ptr, c"test-queue.c".ptr, (158 as c_int), c"queue_peek_head(queue) == &variable4".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_head".ptr, c"test-queue.c".ptr, (159 as c_int), c"queue_pop_head(queue) == &variable4".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_peek_head(__local_queue) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_head".ptr, c"test-queue.c".ptr, (160 as c_int), c"queue_peek_head(queue) == &variable3".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_head".ptr, c"test-queue.c".ptr, (161 as c_int), c"queue_pop_head(queue) == &variable3".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_peek_head(__local_queue) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_head".ptr, c"test-queue.c".ptr, (162 as c_int), c"queue_peek_head(queue) == &variable2".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_head".ptr, c"test-queue.c".ptr, (163 as c_int), c"queue_pop_head(queue) == &variable2".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_peek_head(__local_queue) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_head".ptr, c"test-queue.c".ptr, (164 as c_int), c"queue_peek_head(queue) == &variable1".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_head".ptr, c"test-queue.c".ptr, (165 as c_int), c"queue_pop_head(queue) == &variable1".ptr)
        } else {
            0
        }

    }

    if ((((if not ((if unsafe { queue_peek_head(__local_queue) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_peek_head".ptr, c"test-queue.c".ptr, (168 as c_int), c"queue_peek_head(queue) == NULL".ptr)
    } else {
        0
    }

    unsafe { queue_free(__local_queue) }

}

pub fn test_queue_push_tail() -> Unit {
    var __local_queue: *mut _Queue

    var __local_i: c_int

    (__local_queue = queue_new())

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 1000: 1 else: 0) != 0) {
        unsafe { queue_push_tail(__local_queue, ((&raw mut variable1 as *mut c_int) as *mut c_void)) }

        unsafe { queue_push_tail(__local_queue, ((&raw mut variable2 as *mut c_int) as *mut c_void)) }

        unsafe { queue_push_tail(__local_queue, ((&raw mut variable3 as *mut c_int) as *mut c_void)) }

        unsafe { queue_push_tail(__local_queue, ((&raw mut variable4 as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    if ((((if not ((if not (unsafe { queue_is_empty(__local_queue) } != 0): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_tail".ptr, c"test-queue.c".ptr, (188 as c_int), c"!queue_is_empty(queue)".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_tail".ptr, c"test-queue.c".ptr, (191 as c_int), c"queue_pop_head(queue) == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_tail".ptr, c"test-queue.c".ptr, (192 as c_int), c"queue_pop_head(queue) == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_tail".ptr, c"test-queue.c".ptr, (193 as c_int), c"queue_pop_head(queue) == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_head(__local_queue) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_tail".ptr, c"test-queue.c".ptr, (194 as c_int), c"queue_pop_head(queue) == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_tail".ptr, c"test-queue.c".ptr, (197 as c_int), c"queue_pop_tail(queue) == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_tail".ptr, c"test-queue.c".ptr, (198 as c_int), c"queue_pop_tail(queue) == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_tail".ptr, c"test-queue.c".ptr, (199 as c_int), c"queue_pop_tail(queue) == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_tail".ptr, c"test-queue.c".ptr, (200 as c_int), c"queue_pop_tail(queue) == &variable1".ptr)
    } else {
        0
    }

    unsafe { queue_free(__local_queue) }

    (__local_queue = queue_new())

    alloc_test_set_limit((0 as c_int))

    if ((((if not ((if not (unsafe { queue_push_tail(__local_queue, ((&raw mut variable1 as *mut c_int) as *mut c_void)) } != 0): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_push_tail".ptr, c"test-queue.c".ptr, (208 as c_int), c"!queue_push_tail(queue, &variable1)".ptr)
    } else {
        0
    }

    unsafe { queue_free(__local_queue) }

}

pub fn test_queue_pop_tail() -> Unit {
    var __local_queue: *mut _Queue

    (__local_queue = queue_new())

    if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_pop_tail".ptr, c"test-queue.c".ptr, (220 as c_int), c"queue_pop_tail(queue) == NULL".ptr)
    } else {
        0
    }

    unsafe { queue_free(__local_queue) }

    (__local_queue = generate_queue())

    while ((if not (unsafe { queue_is_empty(__local_queue) } != 0): 1 else: 0) != 0) {
        if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_pop_tail".ptr, c"test-queue.c".ptr, (228 as c_int), c"queue_pop_tail(queue) == &variable1".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_pop_tail".ptr, c"test-queue.c".ptr, (229 as c_int), c"queue_pop_tail(queue) == &variable2".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_pop_tail".ptr, c"test-queue.c".ptr, (230 as c_int), c"queue_pop_tail(queue) == &variable3".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_pop_tail".ptr, c"test-queue.c".ptr, (231 as c_int), c"queue_pop_tail(queue) == &variable4".ptr)
        } else {
            0
        }

    }

    if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_pop_tail".ptr, c"test-queue.c".ptr, (234 as c_int), c"queue_pop_tail(queue) == NULL".ptr)
    } else {
        0
    }

    unsafe { queue_free(__local_queue) }

}

pub fn test_queue_peek_tail() -> Unit {
    var __local_queue: *mut _Queue

    (__local_queue = queue_new())

    if ((((if not ((if unsafe { queue_peek_tail(__local_queue) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_peek_tail".ptr, c"test-queue.c".ptr, (246 as c_int), c"queue_peek_tail(queue) == NULL".ptr)
    } else {
        0
    }

    unsafe { queue_free(__local_queue) }

    (__local_queue = generate_queue())

    while ((if not (unsafe { queue_is_empty(__local_queue) } != 0): 1 else: 0) != 0) {
        if ((((if not ((if unsafe { queue_peek_tail(__local_queue) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_tail".ptr, c"test-queue.c".ptr, (255 as c_int), c"queue_peek_tail(queue) == &variable1".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_tail".ptr, c"test-queue.c".ptr, (256 as c_int), c"queue_pop_tail(queue) == &variable1".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_peek_tail(__local_queue) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_tail".ptr, c"test-queue.c".ptr, (257 as c_int), c"queue_peek_tail(queue) == &variable2".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_tail".ptr, c"test-queue.c".ptr, (258 as c_int), c"queue_pop_tail(queue) == &variable2".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_peek_tail(__local_queue) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_tail".ptr, c"test-queue.c".ptr, (259 as c_int), c"queue_peek_tail(queue) == &variable3".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_tail".ptr, c"test-queue.c".ptr, (260 as c_int), c"queue_pop_tail(queue) == &variable3".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_peek_tail(__local_queue) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_tail".ptr, c"test-queue.c".ptr, (261 as c_int), c"queue_peek_tail(queue) == &variable4".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { queue_pop_tail(__local_queue) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_queue_peek_tail".ptr, c"test-queue.c".ptr, (262 as c_int), c"queue_pop_tail(queue) == &variable4".ptr)
        } else {
            0
        }

    }

    if ((((if not ((if unsafe { queue_peek_tail(__local_queue) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_peek_tail".ptr, c"test-queue.c".ptr, (265 as c_int), c"queue_peek_tail(queue) == NULL".ptr)
    } else {
        0
    }

    unsafe { queue_free(__local_queue) }

}

pub fn test_queue_is_empty() -> Unit {
    var __local_queue: *mut _Queue

    (__local_queue = queue_new())

    if ((((if not (unsafe { queue_is_empty(__local_queue) } != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_is_empty".ptr, c"test-queue.c".ptr, (275 as c_int), c"queue_is_empty(queue)".ptr)
    } else {
        0
    }

    unsafe { queue_push_head(__local_queue, ((&raw mut variable1 as *mut c_int) as *mut c_void)) }

    if ((((if not ((if not (unsafe { queue_is_empty(__local_queue) } != 0): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_is_empty".ptr, c"test-queue.c".ptr, (278 as c_int), c"!queue_is_empty(queue)".ptr)
    } else {
        0
    }

    unsafe { queue_pop_head(__local_queue) }

    if ((((if not (unsafe { queue_is_empty(__local_queue) } != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_is_empty".ptr, c"test-queue.c".ptr, (281 as c_int), c"queue_is_empty(queue)".ptr)
    } else {
        0
    }

    unsafe { queue_push_tail(__local_queue, ((&raw mut variable1 as *mut c_int) as *mut c_void)) }

    if ((((if not ((if not (unsafe { queue_is_empty(__local_queue) } != 0): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_is_empty".ptr, c"test-queue.c".ptr, (284 as c_int), c"!queue_is_empty(queue)".ptr)
    } else {
        0
    }

    unsafe { queue_pop_tail(__local_queue) }

    if ((((if not (unsafe { queue_is_empty(__local_queue) } != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_queue_is_empty".ptr, c"test-queue.c".ptr, (287 as c_int), c"queue_is_empty(queue)".ptr)
    } else {
        0
    }

    unsafe { queue_free(__local_queue) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [9]extern "C" fn() -> Unit = [test_queue_new_free, test_queue_push_head, test_queue_pop_head, test_queue_peek_head, test_queue_push_tail, test_queue_pop_tail, test_queue_peek_tail, test_queue_is_empty, null]
