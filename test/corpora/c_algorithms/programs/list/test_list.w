// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.compare_int
use std.calg_testing.framework
use std.calg_testing.list
use std.libc

pub fn generate_list() -> *mut _ListEntry {
    var __local_list: *mut _ListEntry = ((null as *mut _ListEntry))

    if ((((if not ((if unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"generate_list".ptr, c"test-list.c".ptr, (38 as c_int), c"list_append(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable2 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"generate_list".ptr, c"test-list.c".ptr, (39 as c_int), c"list_append(&list, &variable2) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable3 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"generate_list".ptr, c"test-list.c".ptr, (40 as c_int), c"list_append(&list, &variable3) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable4 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"generate_list".ptr, c"test-list.c".ptr, (41 as c_int), c"list_append(&list, &variable4) != NULL".ptr)
    } else {
        0
    }

    return __local_list

}

pub unsafe fn check_list_integrity(__param_list: *mut _ListEntry) -> Unit {
    var __local_prev: *mut _ListEntry

    var __local_rover: *mut _ListEntry

    (__local_prev = ((null as *mut _ListEntry)))

    (__local_rover = __param_list)

    while ((if __local_rover != null: 1 else: 0) != 0) {
        if ((((if not ((if list_prev(__local_rover) == __local_prev: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"check_list_integrity".ptr, c"test-list.c".ptr, (55 as c_int), c"list_prev(rover) == prev".ptr)
        } else {
            0
        }

        (__local_prev = __local_rover)

        (__local_rover = list_next(__local_rover))

    }

}

pub fn test_list_append() -> Unit {
    var __local_list: *mut _ListEntry = ((null as *mut _ListEntry))

    if ((((if not ((if unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (65 as c_int), c"list_append(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((((if not ((if unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable2 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (67 as c_int), c"list_append(&list, &variable2) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((((if not ((if unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable3 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (69 as c_int), c"list_append(&list, &variable3) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((((if not ((if unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable4 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (71 as c_int), c"list_append(&list, &variable4) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((((if not ((if unsafe { list_length(__local_list) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (74 as c_int), c"list_length(list) == 4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_nth_data(__local_list, (0 as c_uint)) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (76 as c_int), c"list_nth_data(list, 0) == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_nth_data(__local_list, (1 as c_uint)) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (77 as c_int), c"list_nth_data(list, 1) == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_nth_data(__local_list, (2 as c_uint)) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (78 as c_int), c"list_nth_data(list, 2) == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_nth_data(__local_list, (3 as c_uint)) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (79 as c_int), c"list_nth_data(list, 3) == &variable4".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as c_int))

    if ((((if not ((if unsafe { list_length(__local_list) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (83 as c_int), c"list_length(list) == 4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (84 as c_int), c"list_append(&list, &variable1) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_length(__local_list) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (85 as c_int), c"list_length(list) == 4".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    unsafe { list_free(__local_list) }

}

pub fn test_list_prepend() -> Unit {
    var __local_list: *mut _ListEntry = ((null as *mut _ListEntry))

    if ((((if not ((if unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (95 as c_int), c"list_prepend(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((((if not ((if unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable2 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (97 as c_int), c"list_prepend(&list, &variable2) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((((if not ((if unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable3 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (99 as c_int), c"list_prepend(&list, &variable3) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((((if not ((if unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable4 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (101 as c_int), c"list_prepend(&list, &variable4) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((((if not ((if unsafe { list_nth_data(__local_list, (0 as c_uint)) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (104 as c_int), c"list_nth_data(list, 0) == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_nth_data(__local_list, (1 as c_uint)) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (105 as c_int), c"list_nth_data(list, 1) == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_nth_data(__local_list, (2 as c_uint)) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (106 as c_int), c"list_nth_data(list, 2) == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_nth_data(__local_list, (3 as c_uint)) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (107 as c_int), c"list_nth_data(list, 3) == &variable1".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as c_int))

    if ((((if not ((if unsafe { list_length(__local_list) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (111 as c_int), c"list_length(list) == 4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (112 as c_int), c"list_prepend(&list, &variable1) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_length(__local_list) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (113 as c_int), c"list_length(list) == 4".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    unsafe { list_free(__local_list) }

}

pub fn test_list_free() -> Unit {
    var __local_list: *mut _ListEntry

    (__local_list = generate_list())

    unsafe { list_free(__local_list) }

    unsafe { list_free((null as *mut _ListEntry)) }

}

pub fn test_list_next() -> Unit {
    var __local_list: *mut _ListEntry

    var __local_rover: *mut _ListEntry

    (__local_list = generate_list())

    (__local_rover = __local_list)

    if ((((if not ((if unsafe { list_data(__local_rover) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_next".ptr, c"test-list.c".ptr, (140 as c_int), c"list_data(rover) == &variable1".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { list_next(__local_rover) })

    if ((((if not ((if unsafe { list_data(__local_rover) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_next".ptr, c"test-list.c".ptr, (142 as c_int), c"list_data(rover) == &variable2".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { list_next(__local_rover) })

    if ((((if not ((if unsafe { list_data(__local_rover) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_next".ptr, c"test-list.c".ptr, (144 as c_int), c"list_data(rover) == &variable3".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { list_next(__local_rover) })

    if ((((if not ((if unsafe { list_data(__local_rover) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_next".ptr, c"test-list.c".ptr, (146 as c_int), c"list_data(rover) == &variable4".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { list_next(__local_rover) })

    if ((((if not ((if __local_rover == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_next".ptr, c"test-list.c".ptr, (148 as c_int), c"rover == NULL".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

}

pub fn test_list_nth_entry() -> Unit {
    var __local_list: *mut _ListEntry

    var __local_entry: *mut _ListEntry

    (__local_list = generate_list())

    (__local_entry = unsafe { list_nth_entry(__local_list, (0 as c_uint)) })

    if ((((if not ((if unsafe { list_data(__local_entry) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_nth_entry".ptr, c"test-list.c".ptr, (162 as c_int), c"list_data(entry) == &variable1".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { list_nth_entry(__local_list, (1 as c_uint)) })

    if ((((if not ((if unsafe { list_data(__local_entry) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_nth_entry".ptr, c"test-list.c".ptr, (164 as c_int), c"list_data(entry) == &variable2".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { list_nth_entry(__local_list, (2 as c_uint)) })

    if ((((if not ((if unsafe { list_data(__local_entry) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_nth_entry".ptr, c"test-list.c".ptr, (166 as c_int), c"list_data(entry) == &variable3".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { list_nth_entry(__local_list, (3 as c_uint)) })

    if ((((if not ((if unsafe { list_data(__local_entry) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_nth_entry".ptr, c"test-list.c".ptr, (168 as c_int), c"list_data(entry) == &variable4".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { list_nth_entry(__local_list, (4 as c_uint)) })

    if ((((if not ((if __local_entry == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_nth_entry".ptr, c"test-list.c".ptr, (172 as c_int), c"entry == NULL".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { list_nth_entry(__local_list, (400 as c_uint)) })

    if ((((if not ((if __local_entry == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_nth_entry".ptr, c"test-list.c".ptr, (174 as c_int), c"entry == NULL".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

}

pub fn test_list_nth_data() -> Unit {
    var __local_list: *mut _ListEntry

    (__local_list = generate_list())

    if ((((if not ((if unsafe { list_nth_data(__local_list, (0 as c_uint)) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_nth_data".ptr, c"test-list.c".ptr, (186 as c_int), c"list_nth_data(list, 0) == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_nth_data(__local_list, (1 as c_uint)) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_nth_data".ptr, c"test-list.c".ptr, (187 as c_int), c"list_nth_data(list, 1) == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_nth_data(__local_list, (2 as c_uint)) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_nth_data".ptr, c"test-list.c".ptr, (188 as c_int), c"list_nth_data(list, 2) == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_nth_data(__local_list, (3 as c_uint)) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_nth_data".ptr, c"test-list.c".ptr, (189 as c_int), c"list_nth_data(list, 3) == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_nth_data(__local_list, (4 as c_uint)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_nth_data".ptr, c"test-list.c".ptr, (192 as c_int), c"list_nth_data(list, 4) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_nth_data(__local_list, (400 as c_uint)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_nth_data".ptr, c"test-list.c".ptr, (193 as c_int), c"list_nth_data(list, 400) == NULL".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

}

pub fn test_list_length() -> Unit {
    var __local_list: *mut _ListEntry

    (__local_list = generate_list())

    if ((((if not ((if unsafe { list_length(__local_list) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_length".ptr, c"test-list.c".ptr, (205 as c_int), c"list_length(list) == 4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_length".ptr, c"test-list.c".ptr, (208 as c_int), c"list_prepend(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_length(__local_list) } == 5: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_length".ptr, c"test-list.c".ptr, (210 as c_int), c"list_length(list) == 5".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

    if ((((if not ((if unsafe { list_length((null as *mut _ListEntry)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_length".ptr, c"test-list.c".ptr, (215 as c_int), c"list_length(NULL) == 0".ptr)
    } else {
        0
    }

}

pub fn test_list_remove_entry() -> Unit {
    var __local_empty_list: *mut _ListEntry = ((null as *mut _ListEntry))

    var __local_list: *mut _ListEntry

    var __local_entry: *mut _ListEntry

    (__local_list = generate_list())

    (__local_entry = unsafe { list_nth_entry(__local_list, (2 as c_uint)) })

    if ((((if not ((if unsafe { list_remove_entry((&raw mut __local_list as *mut *mut _ListEntry), __local_entry) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (228 as c_int), c"list_remove_entry(&list, entry) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_length(__local_list) } == 3: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (229 as c_int), c"list_length(list) == 3".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    (__local_entry = unsafe { list_nth_entry(__local_list, (0 as c_uint)) })

    if ((((if not ((if unsafe { list_remove_entry((&raw mut __local_list as *mut *mut _ListEntry), __local_entry) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (234 as c_int), c"list_remove_entry(&list, entry) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_length(__local_list) } == 2: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (235 as c_int), c"list_length(list) == 2".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((((if not ((if unsafe { list_remove_entry((&raw mut __local_list as *mut *mut _ListEntry), (null as *mut _ListEntry)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (240 as c_int), c"list_remove_entry(&list, NULL) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_remove_entry((&raw mut __local_empty_list as *mut *mut _ListEntry), (null as *mut _ListEntry)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (243 as c_int), c"list_remove_entry(&empty_list, NULL) == 0".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

    (__local_list = ((null as *mut _ListEntry)))

    if ((((if not ((if unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (249 as c_int), c"list_append(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if __local_list != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (250 as c_int), c"list != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_remove_entry((&raw mut __local_list as *mut *mut _ListEntry), __local_list) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (251 as c_int), c"list_remove_entry(&list, list) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if __local_list == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (252 as c_int), c"list == NULL".ptr)
    } else {
        0
    }

    (__local_list = generate_list())

    (__local_entry = unsafe { list_nth_entry(__local_list, (3 as c_uint)) })

    if ((((if not ((if unsafe { list_remove_entry((&raw mut __local_list as *mut *mut _ListEntry), __local_entry) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (257 as c_int), c"list_remove_entry(&list, entry) != 0".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    unsafe { list_free(__local_list) }

}

pub fn test_list_remove_data() -> Unit {
    var __local_entries: [13]c_int = [(89 as c_int), (4 as c_int), (23 as c_int), (42 as c_int), (4 as c_int), (16 as c_int), (15 as c_int), (4 as c_int), (8 as c_int), (99 as c_int), (50 as c_int), (30 as c_int), (4 as c_int)]

    var __local_num_entries: c_uint = ((13 as c_uint))

    var __local_val: c_int

    var __local_list: *mut _ListEntry

    var __local_i: c_uint

    (__local_list = ((null as *mut _ListEntry)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        if ((((if not ((if unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), (((&raw const __local_entries[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (274 as c_int), c"list_prepend(&list, &entries[i]) != NULL".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_val = ((0 as c_int)))

    if ((((if not ((if unsafe { list_remove_data((&raw mut __local_list as *mut *mut _ListEntry), int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (279 as c_int), c"list_remove_data(&list, int_equal, &val) == 0".ptr)
    } else {
        0
    }

    (__local_val = ((56 as c_int)))

    if ((((if not ((if unsafe { list_remove_data((&raw mut __local_list as *mut *mut _ListEntry), int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (281 as c_int), c"list_remove_data(&list, int_equal, &val) == 0".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    (__local_val = ((8 as c_int)))

    if ((((if not ((if unsafe { list_remove_data((&raw mut __local_list as *mut *mut _ListEntry), int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == 1: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (286 as c_int), c"list_remove_data(&list, int_equal, &val) == 1".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_length(__local_list) } == ((__local_num_entries as c_uint) -% (1 as c_uint)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (287 as c_int), c"list_length(list) == num_entries - 1".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    (__local_val = ((4 as c_int)))

    if ((((if not ((if unsafe { list_remove_data((&raw mut __local_list as *mut *mut _ListEntry), int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (292 as c_int), c"list_remove_data(&list, int_equal, &val) == 4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_length(__local_list) } == ((__local_num_entries as c_uint) -% (5 as c_uint)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (293 as c_int), c"list_length(list) == num_entries - 5".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    (__local_val = ((89 as c_int)))

    if ((((if not ((if unsafe { list_remove_data((&raw mut __local_list as *mut *mut _ListEntry), int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == 1: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (298 as c_int), c"list_remove_data(&list, int_equal, &val) == 1".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_length(__local_list) } == ((__local_num_entries as c_uint) -% (6 as c_uint)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (299 as c_int), c"list_length(list) == num_entries - 6".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    unsafe { list_free(__local_list) }

}

pub fn test_list_sort() -> Unit {
    var __local_list: *mut _ListEntry

    var __local_entries: [13]c_int = [(89 as c_int), (4 as c_int), (23 as c_int), (42 as c_int), (4 as c_int), (16 as c_int), (15 as c_int), (4 as c_int), (8 as c_int), (99 as c_int), (50 as c_int), (30 as c_int), (4 as c_int)]

    var __local_sorted: [13]c_int = [(4 as c_int), (4 as c_int), (4 as c_int), (4 as c_int), (8 as c_int), (15 as c_int), (16 as c_int), (23 as c_int), (30 as c_int), (42 as c_int), (50 as c_int), (89 as c_int), (99 as c_int)]

    var __local_num_entries: c_uint = ((13 as c_uint))

    var __local_i: c_uint

    (__local_list = ((null as *mut _ListEntry)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        if ((((if not ((if unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), (((&raw const __local_entries[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_list_sort".ptr, c"test-list.c".ptr, (316 as c_int), c"list_prepend(&list, &entries[i]) != NULL".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { list_sort((&raw mut __local_list as *mut *mut _ListEntry), int_compare) }

    if ((((if not ((if unsafe { list_length(__local_list) } == __local_num_entries: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_sort".ptr, c"test-list.c".ptr, (322 as c_int), c"list_length(list) == num_entries".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        var __local_value: *mut c_int

        (__local_value = ((unsafe { list_nth_data(__local_list, __local_i) } as *mut c_int)))

        if ((((if not ((if (unsafe *__local_value) == __local_sorted[__local_i]: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_list_sort".ptr, c"test-list.c".ptr, (329 as c_int), c"*value == sorted[i]".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { list_free(__local_list) }

    (__local_list = ((null as *mut _ListEntry)))

    unsafe { list_sort((&raw mut __local_list as *mut *mut _ListEntry), int_compare) }

    if ((((if not ((if __local_list == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_sort".ptr, c"test-list.c".ptr, (339 as c_int), c"list == NULL".ptr)
    } else {
        0
    }

}

pub fn test_list_find_data() -> Unit {
    var __local_entries: [10]c_int = [(89 as c_int), (23 as c_int), (42 as c_int), (16 as c_int), (15 as c_int), (4 as c_int), (8 as c_int), (99 as c_int), (50 as c_int), (30 as c_int)]

    var __local_num_entries: c_int = ((10 as c_int))

    var __local_list: *mut _ListEntry

    var __local_result: *mut _ListEntry

    var __local_i: c_int

    var __local_val: c_int

    var __local_data: *mut c_int

    (__local_list = ((null as *mut _ListEntry)))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        if ((((if not ((if unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), (((&raw const __local_entries[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_list_find_data".ptr, c"test-list.c".ptr, (355 as c_int), c"list_append(&list, &entries[i]) != NULL".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((0 as c_int)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        (__local_val = ((__local_entries[__local_i] as c_int)))

        (__local_result = unsafe { list_find_data(__local_list, int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) })

        if ((((if not ((if __local_result != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_list_find_data".ptr, c"test-list.c".ptr, (365 as c_int), c"result != NULL".ptr)
        } else {
            0
        }

        (__local_data = ((unsafe { list_data(__local_result) } as *mut c_int)))

        if ((((if not ((if (unsafe *__local_data) == __local_val: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_list_find_data".ptr, c"test-list.c".ptr, (368 as c_int), c"*data == val".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_val = ((0 as c_int)))

    if ((((if not ((if unsafe { list_find_data(__local_list, int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_find_data".ptr, c"test-list.c".ptr, (373 as c_int), c"list_find_data(list, int_equal, &val) == NULL".ptr)
    } else {
        0
    }

    (__local_val = ((56 as c_int)))

    if ((((if not ((if unsafe { list_find_data(__local_list, int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_find_data".ptr, c"test-list.c".ptr, (375 as c_int), c"list_find_data(list, int_equal, &val) == NULL".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

}

pub fn test_list_to_array() -> Unit {
    var __local_list: *mut _ListEntry

    var __local_array: *mut *mut c_void

    (__local_list = generate_list())

    (__local_array = unsafe { list_to_array(__local_list) })

    if ((((if not ((if (unsafe __local_array[0]) == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_to_array".ptr, c"test-list.c".ptr, (389 as c_int), c"array[0] == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe __local_array[1]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_to_array".ptr, c"test-list.c".ptr, (390 as c_int), c"array[1] == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe __local_array[2]) == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_to_array".ptr, c"test-list.c".ptr, (391 as c_int), c"array[2] == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe __local_array[3]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_to_array".ptr, c"test-list.c".ptr, (392 as c_int), c"array[3] == &variable4".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free((__local_array as *mut c_void)) }

    alloc_test_set_limit((0 as c_int))

    (__local_array = unsafe { list_to_array(__local_list) })

    if ((((if not ((if __local_array == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_to_array".ptr, c"test-list.c".ptr, (400 as c_int), c"array == NULL".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

}

pub fn test_list_iterate() -> Unit {
    var __local_list: *mut _ListEntry

    var __local_iter: _ListIterator

    var __local_i: c_int

    var __local_a: c_int

    var __local_counter: c_int

    var __local_data: *mut c_int

    (__local_list = ((null as *mut _ListEntry)))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 50: 1 else: 0) != 0) {
        if ((((if not ((if unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut __local_a as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (418 as c_int), c"list_prepend(&list, &a) != NULL".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_counter = ((0 as c_int)))

    unsafe { list_iterate((&raw mut __local_list as *mut *mut _ListEntry), (&raw mut __local_iter as *mut _ListIterator)) }

    unsafe { list_iter_remove((&raw mut __local_iter as *mut _ListIterator)) }

    while (unsafe { list_iter_has_more((&raw mut __local_iter as *mut _ListIterator)) } != 0) {
        (__local_data = ((unsafe { list_iter_next((&raw mut __local_iter as *mut _ListIterator)) } as *mut c_int)))

        if ((((if not ((if __local_data != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (432 as c_int), c"data != NULL".ptr)
        } else {
            0
        }

        (__local_counter = __local_counter + 1)

        if ((if (__local_counter % 2) == 0: 1 else: 0) != 0) {
            unsafe { list_iter_remove((&raw mut __local_iter as *mut _ListIterator)) }

            unsafe { list_iter_remove((&raw mut __local_iter as *mut _ListIterator)) }

        }

    }

    if ((((if not ((if unsafe { list_iter_next((&raw mut __local_iter as *mut _ListIterator)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (445 as c_int), c"list_iter_next(&iter) == NULL".ptr)
    } else {
        0
    }

    unsafe { list_iter_remove((&raw mut __local_iter as *mut _ListIterator)) }

    if ((((if not ((if __local_counter == 50: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (450 as c_int), c"counter == 50".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { list_length(__local_list) } == 25: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (451 as c_int), c"list_length(list) == 25".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

    (__local_list = ((null as *mut _ListEntry)))

    (__local_counter = ((0 as c_int)))

    unsafe { list_iterate((&raw mut __local_list as *mut *mut _ListEntry), (&raw mut __local_iter as *mut _ListIterator)) }

    while (unsafe { list_iter_has_more((&raw mut __local_iter as *mut _ListIterator)) } != 0) {
        (__local_data = ((unsafe { list_iter_next((&raw mut __local_iter as *mut _ListIterator)) } as *mut c_int)))

        if ((((if not ((if __local_data != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (463 as c_int), c"data != NULL".ptr)
        } else {
            0
        }

        (__local_counter = __local_counter + 1)

    }

    if ((((if not ((if __local_counter == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (467 as c_int), c"counter == 0".ptr)
    } else {
        0
    }

}

pub fn test_list_iterate_bad_remove() -> Unit {
    var __local_list: *mut _ListEntry

    var __local_iter: _ListIterator

    var __local_values: [49]c_int

    var __local_i: c_int

    var __local_val: *mut c_int

    (__local_list = ((null as *mut _ListEntry)))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 49: 1 else: 0) != 0) {
        (__local_values[__local_i] = __local_i)

        if ((((if not ((if unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), (((&raw const __local_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_list_iterate_bad_remove".ptr, c"test-list.c".ptr, (485 as c_int), c"list_prepend(&list, &values[i]) != NULL".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { list_iterate((&raw mut __local_list as *mut *mut _ListEntry), (&raw mut __local_iter as *mut _ListIterator)) }

    while (unsafe { list_iter_has_more((&raw mut __local_iter as *mut _ListIterator)) } != 0) {
        (__local_val = ((unsafe { list_iter_next((&raw mut __local_iter as *mut _ListIterator)) } as *mut c_int)))

        if ((if ((unsafe *__local_val) % 2) == 0: 1 else: 0) != 0) {
            if ((((if not ((if unsafe { list_remove_data((&raw mut __local_list as *mut *mut _ListEntry), int_equal, (__local_val as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
                __assert_rtn(c"test_list_iterate_bad_remove".ptr, c"test-list.c".ptr, (500 as c_int), c"list_remove_data(&list, int_equal, val) != 0".ptr)
            } else {
                0
            }

            unsafe { list_iter_remove((&raw mut __local_iter as *mut _ListIterator)) }

        }

    }

    unsafe { list_free(__local_list) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [15]extern "C" fn() -> Unit = [test_list_append, test_list_prepend, test_list_free, test_list_next, test_list_nth_entry, test_list_nth_data, test_list_length, test_list_remove_entry, test_list_remove_data, test_list_sort, test_list_find_data, test_list_to_array, test_list_iterate, test_list_iterate_bad_remove, null]
